jQuery ->
    toType = (obj) ->
        ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()

    Backbone.sync = (method, model, options) =>
        console.log "in sync"
        switch method
            when "create"
                console.log "create #{model._id}"
                $.ajax(
                    type: "POST"
                    url: "/icecream/products"
                    data: JSON.parse(JSON.stringify model)
                    async: true
                    cache: false
                    timeout: 50000

                    success: (data) ->
                        console.log data
                        options.success data
                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert ["/icecream/products", textStatus, textStatus, errorThrown]
                        options.error
                )
            when "read"
                console.log "read #{model._id}"
                $.ajax(
                    type: "GET"
                    url: "/icecream/products/" + model._id
                    data: JSON.parse(JSON.stringify model)
                    async: true
                    cache: false
                    timeout: 50000

                    success: (data) ->
                        data = JSON.parse data
                        console.log data
                        options.success data
                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert ["/icecream/products", textStatus, textStatus, errorThrown]
                        options.error
                )
            when "update"
                console.log "update #{model._id}"
                $.ajax(
                    type: "PUT"
                    url: "/icecream/products/" + model._id
                    data: JSON.parse(JSON.stringify model)
                    async: true
                    cache: false
                    timeout: 50000

                    success: (data) ->
                        console.log data
                        options.success data
                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert ["/icecream/products", textStatus, textStatus, errorThrown]
                        options.error
                )
            when "delete"
                console.log "delete #{model._id}"
                $.ajax(
                    type: "DELETE"
                    url: "/icecream/products/" + model._id
                    async: true
                    cache: false
                    timeout: 50000

                    success: (data) ->
                        console.log data
                        options.success data
                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert ["/icecream/products", textStatus, textStatus, errorThrown]
                        options.error
                )

    class Product extends Backbone.Model
        defaults:
            number_of_purchases: 0

    class ProductsModel extends Backbone.Collection
        url: '/icecream/products'
                    

    class ProductsView extends Backbone.View
        el: '.products'
        spin_first: (opt) ->
            @$('.product:first').spin(opt)
        render: ->
            console.log "render"
            console.log @$el
            @$el.empty()
            @collection.each (element) =>
                parsed_json = JSON.parse(JSON.stringify element)
                console.log parsed_json
                dust.render '/dust/admin_product_item_template', parsed_json, (err, out) =>
                    @$el.append out


    products = new ProductsModel()
    products_view = new ProductsView(collection: products)


    initialize = ->
        console.log "initializing..."

        products.on 'remove', (name) ->
            console.log 'remove event callback'
            products_view.render()

        products.on 'reset', (name) ->
            console.log 'reset event callback'
            products_view.render()

        products.on 'sync', (name) ->
            console.log 'sync event callback'
            products_view.render()

        products.on 'add', (name) ->
            console.log 'add event callback'
            products_view.render()
        
        $('.close').live 'click', ->
            console.log 'click close'
            product_id = $(this).parent().find('#product_id').text().split(' ')[2]
            products.remove [products.find (item) -> item.get("_id") == product_id]

        $('form#add-product-form').ajaxForm
            beforeSubmit: (arr, $form, options) ->
                console.log 'add-product-form'
                console.log arr
                options = {}
                options = _.reduce arr, ((abs, thing) -> abs[thing.name] = thing.value; abs), {}
                console.log options
                model = new Product(options)
                model.save
                    success: (data) =>
                        products_view.spin_first(false)
                products.unshift model
                products_view.spin_first()
                false
            success: (data) ->
                console.log data
            error: (XMLHttpRequest, textStatus, errorThrown) ->
                alert ["/icecream/products", textStatus, textStatus, errorThrown]

        products.fetch()

    initialize()
