jQuery ->
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

    # old stuff
    poll = (url, type, success, error, debug) ->
        console.log "polling for #{url}..."
        $.ajax(
            type: type
            url: url
            async: true
            cache: false
            timeout: 50000

            success: (data) ->
                data = JSON.parse data
                if debug
                    console.log data
                success(data)
                setTimeout(poll, 1000)
            error: (XMLHttpRequest, textStatus, errorThrown) ->
                console.log 'error', textStatus, errorThrown
                error(XMLHttpRequest, textStatus, errorThrown)
                setTimeout(poll, 2000)
        )

###
            $('#number-of-pepsi').text(data[0])
            $('#leftovers-of-pepsi').text(data[1])
            if data[0] == 0
                $('#motivation-speech').text('put yourself first in line!')
            else if data[0] < 4
                $('#motivation-speech').text('join the line right now!')
            else if data[0] < 9
                $('#motivation-speech').text('we are so close, only need a few more')
            else if data[0] == 10
                $('#motivation-speech').text('thanks for everyone who have clicked on the button, nothing will be shipped, it is a scam! Muhahahaha')
###
