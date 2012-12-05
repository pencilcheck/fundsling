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
                    url: "/orders/" + model._id
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
            when "delete"
                console.log "delete #{model._id}"
                $.ajax(
                    type: "DELETE"
                    url: "/orders/" + model._id
                    async: true
                    cache: false
                    timeout: 50000

                    success: (data) ->
                        console.log data
                        options.success data
                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert ["/icecream/orders", textStatus, textStatus, errorThrown]
                        options.error
                )

    class OrdersModel extends Backbone.Collection
        url: '/orders'
                    

    class CartView extends Backbone.View
        el: '.cart'
        render: ->
            console.log "render"
            console.log @$el
            @$el.empty()
            @collection.each (element) =>
                parsed_json = JSON.parse(JSON.stringify element)
                console.log parsed_json
                dust.render '/dust/cart_order_item_template', parsed_json, (err, out) =>
                    @$el.append out


    orders = new OrdersModel()
    cart_view = new CartView(collection: orders)


    initialize = ->
        console.log "initializing..."

        orders.on 'remove', (name) ->
            console.log 'remove event callback'
            cart_view.render()

        orders.on 'reset', (name) ->
            console.log 'reset event callback'
            cart_view.render()

        orders.on 'sync', (name) ->
            console.log 'sync event callback'
            cart_view.render()

        orders.on 'add', (name) ->
            console.log 'add event callback'
            cart_view.render()
        
        $('.close').live 'click', ->
            console.log 'click close'
            order_id = $(this).parent().find('#order_id').text().split(' ')[2]
            orders.remove [orders.find (item) -> item.get("_id") == order_id]

        orders.fetch()


    initialize()


