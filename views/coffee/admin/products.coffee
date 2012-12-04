products = []

initialize = () ->
    console.log "initializing..."

    $('form#add-product-form').ajaxForm
        success: (data) ->
            data = JSON.parse data
            console.log data
            products.splice 0, 0, data
            refresh()

    $.ajax(
        type: "POST"
        url: "/icecream/products"
        async: true
        cache: false
        timeout: 50000

        success: (data) ->
            data = JSON.parse data
            products = data
            _.each products, (item) ->
                dust.render '/dust/admin_product_item_template', item, (err, out) ->
                    $('.products').append out
        error: (XMLHttpRequest, textStatus, errorThrown) ->
            console.log 'error', textStatus, errorThrown
            error(XMLHttpRequest, textStatus, errorThrown)
    )

refresh = () ->
    if products.length > 0
        $('.products').empty()
        _.each products, (item) ->
            dust.render '/dust/admin_product_item_template', item, (err, out) ->
                $('.products').append out


initialize()
