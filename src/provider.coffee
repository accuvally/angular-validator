
$ = angular.element
a = angular.module 'validator.provider', []

a.provider '$validator', ->
    # ----------------------------
    # providers
    # ----------------------------
    $injector = null

    # ----------------------------
    # properties
    # ----------------------------
    @rules = {}

    # ----------------------------
    # init
    # ----------------------------
    init =
        all: ->
            do @[x] for x of @ when x isnt 'all'
            return

    # ----------------------------
    # private functions
    # ----------------------------
    setupProviders = (injector) ->
        $injector = injector

    # ----------------------------
    # public functions
    # ----------------------------
    @convertRule = (object={}) ->
        ###
        Convert the rule object.
        ###
        result =
            enableError: false
            invoke: object.invoke
            filter: object.filter
            validator: object.validator
            error: object.error
            success: object.success

        result.invoke ?= []
        result.filter ?= (input) -> input
        result.validator ?= -> true
        result.error ?= ''
        result.enableError = 'watch' in result.invoke

        # convert error
        if result.error.constructor is String
            errorMessage = result.error
            result.error = (element, attrs) ->
                parent = $(element).parent()
                for index in [1..3]
                    if parent.hasClass('form-group')
                        $(element).parent().append "<label class='control-label error'>#{errorMessage}</label>"
                        parent.addClass('has-error')
                        break
                    parent = parent.parent()

        # convert success
        successFunc = (element, attrs) ->
            parent = $(element).parent()
            for index in [1..3]
                if parent.hasClass('has-error')
                    parent.removeClass('has-error')
                    for label in parent.find('label') when $(label).hasClass 'error'
                        label.remove()
                        break
                    break
                parent = parent.parent()
        if result.success and typeof(result.success) is 'function'
            # swop
            func = result.success
            result.success = (element, attrs) ->
                func element, attrs
                successFunc element, attrs
        else
            result.success = successFunc


        # convert validator
        if result.validator.constructor is RegExp
            regex = result.validator
            result.validator = (value, element, attrs) ->
                if regex.test value
                    result.success element, attrs
                else
                    if result.enableError
                        result.error element, attrs

        else if typeof(result.validator) is 'function' or result.validator.constructor is Array
            func = result.validator
            result.validator = (value, scope, element, attrs, isFromWatch=false) ->
                func.$injectx =
                    $http: $injector.get '$http'
                    value: value
                    scope: scope
                    element: element
                    attrs: attrs
                    isFromWatch: isFromWatch
#                if result.validator.$inject
#                    if result.validator.$inject.constructor is Array
#                        for item in result.validator.$inject.constructor
#                            func.$inject[item] = $injector.get item
                $injector.invoke(func)


        result

    @register = (name, object={}) ->
        ###
        Register the rules.
        @params name: The rule name.
        @params object:
            invoke: ['watch', 'blur'] or undefined(validator by yourself)
            filter: function(input)
            validator: RegExp() or function(value, element, attrs, $injector)
            error: string or function(element, attrs)
            success: function(element, attrs)
        ###
        # set rule
        @rules[name] = @convertRule object

    @getRule = (name) ->
        if @rules[name] then @rules[name] else null

    @validate = (scope) ->


    # ----------------------------
    # $get
    # ----------------------------
    @get = ($injector) ->
        setupProviders $injector
        do init.all

        rules: @rules
        getRule: @getRule
        validate: @validate
    @get.$inject = ['$injector']
    @$get = @get
