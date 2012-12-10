jQuery ->
    ###
    toType = (obj) ->
        ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()

    Backbone.sync = (method, model, options) ->
        console.log "in sync"
        switch method
            when "read"
                console.log "read #{model._id}"
                $.ajax(
                    type: "GET"
                    url: "/products/" + model._id
                    data: JSON.parse(JSON.stringify model)
                    async: true
                    cache: false
                    timeout: 50000

                    success: (data) ->
                        data = JSON.parse data
                        console.log data
                        options.success data
                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert ["/icecream/orders", textStatus, textStatus, errorThrown]
                        options.error
                )

    class ProductsModel extends Backbone.Collection
        url: '/products'
                    

    class CategoryView extends Backbone.View
        el: '.category'
        render: ->
            console.log "render"
            console.log @$el
            @$el.empty()
            @collection.each (element) =>
                parsed_json = JSON.parse(JSON.stringify element)
                console.log parsed_json
                dust.render '/dust/index_product_item_template', parsed_json, (err, out) =>
                    @$el.append out


    products = new ProductsModel()
    category_view = new CategoryView(collection: products)


    initialize = ->
        console.log "initializing..."

        products.on 'remove', (name) ->
            console.log 'remove event callback'
            category_view.render()

        products.on 'reset', (name) ->
            console.log 'reset event callback'
            category_view.render()

        products.on 'sync', (name) ->
            console.log 'sync event callback'
            category_view.render()

        products.on 'add', (name) ->
            console.log 'add event callback'
            category_view.render()
        
        products.fetch()

    initialize()
    ###
