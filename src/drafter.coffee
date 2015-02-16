protagonist = require 'protagonist-experimental'
options = require './options'
fs = require 'fs'

#
# Drafter
#
class Drafter

  # List of data structures
  @dataStructures: {}

  # Default configuration
  @defaultConfig:
    requireBlueprintName: false # Treat missing API name as error
    exportSourcemap: false      # Generate source map

  # Constructor
  #
  # @param config [Object] configuration of the parser (see Drafter.defaultConfig)
  constructor: (@config) ->
    @config = Drafter.defaultConfig if !@config

  # Execute the make process using a file path
  #   this is just a convenience wrapper for @make
  #
  # @param blueprintPath [String] path to the source API Blueprint
  # @param callback [(Error, ParseResult))]
  makeFromPath: (blueprintPath, callback) ->

    fs.readFile blueprintPath, 'utf8', (error, source) =>
      return callback(error) if error

      @make source, callback

  # Parse & process the input source file
  #
  # @param source [String] soruce API Bluerpint code
  # @param callback [(Error, ParseResult)]
  make: (source, callback) ->
    protagonist.parse source, @config, (error, result) =>
      callback error if error

      ruleList = ['mson-inheritance', 'mson-mixin', 'mson-member-type-name']
      rules = (require './rules/' + rule for rule in ruleList)

      @dataStructures = {}
      delete result.ast.resourceGroups

      @expandNode result.ast, rules, 'blueprint'
      @reconstructResourceGroups result.ast

      callback error, result

  # Expand a certain node with the given rules
  #
  # @param node [Object] A node of API Blueprint
  # @param rules [Array] List of rules to apply
  # @param elementTye [String] The element type of the node
  expandNode: (node, rules, elementType) ->
    elementType ?= node.element

    # On root node, Gather data structures first before applying rules to any of the children nodes
    if elementType is 'blueprint'
      for element in node.content

        if element.element is 'category'
          for subElement in element.content

            switch subElement.element
              when 'dataStructure'
                @dataStructures[subElement.name.literal] = subElement
              when 'resource'

                for resourceSubElement in subElement.content
                  @dataStructures[resourceSubElement.name.literal] = resourceSubElement if resourceSubElement.element is 'dataStructure'

      # Expand the gathered data structures
      for rule in rules
        rule.init.call rule, @dataStructures if rule.init

    # Apply rules to the current node
    for rule in rules
      rule[elementType].call rule, node if elementType in Object.keys(rule)

    # Recursively do the same for children nodes
    switch elementType
      when 'resource'
        @expandNode action, rules, 'action' for action in node.actions

      when 'action'
        @expandNode example, rules, 'transactionExample' for example in node.examples

      when 'transactionExample'
        @expandNode request, rules, 'payload' for request in node.requests
        @expandNode response, rules, 'payload' for response in node.responses

    if node.content and Array.isArray node.content
      @expandNode element, rules for element in node.content

  # Reconstruct deprecated resource groups key from elements
  #
  # @param ast [Object] Blueprint ast
  reconstructResourceGroups: (ast) ->
    ast.resourceGroups = []

    for element in ast.content
      if element.element is 'category'
        resources = []

        for subElement in element.content
          resources.push subElement if subElement.element is 'resource'

        if resources.length
          description = element.content[0].content if element.content[0].element is 'copy'

          ast.resourceGroups.push
            name: element.attributes?.name || ''
            description: description || ''
            resources: resources

module.exports = Drafter
module.exports.options = options