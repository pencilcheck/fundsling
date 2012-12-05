orders= []

initialize = () ->
    console.log "initializing..."

    $('form#add-order-form').ajaxForm
        success: (data) ->
            data = JSON.parse data
            console.log data
            orders.splice 0, 0, data
            refresh()

    $.ajax(
        type: "POST"
        url: "/icecream/orders"
        async: true
        cache: false
        timeout: 50000

        success: (data) ->
            data = JSON.parse data
            products = data
            _.each products, (item) ->
                dust.render '/dust/admin_order_item_template', item, (err, out) ->
                    $('.orders').append out
        error: (XMLHttpRequest, textStatus, errorThrown) ->
            console.log 'error', textStatus, errorThrown
            error(XMLHttpRequest, textStatus, errorThrown)
    )

refresh = () ->
    if orders.length > 0
        $('.orders').empty()
        _.each orders, (item) ->
            dust.render '/dust/admin_order_item_template', item, (err, out) ->
                $('.orders').append out


initialize()

