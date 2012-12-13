jQuery ->
    $('#plus').click (e) ->
        remaining = parseInt($('#remaining').text(), 10)
        quantity = parseInt($('#quantity').text(), 10) + 1
        if quantity <= remaining
            $('#quantity').html(quantity)

    $('#minus').click (e) ->
        quantity = parseInt($('#quantity').text(), 10) - 1
        if quantity > 0
            $('#quantity').html(quantity)

    $(document).click ->
        $('#purchase').popover('hide')

    $('#purchase').click (e) ->
        $('#purchase').attr('disabled', 'disabled')
        quantity = parseInt($('#quantity').text(), 10)
        product_id = $('.product-showcase').data('product-id')
        $.ajax(
            type: "GET"
            url: "/orders/create/" + product_id
            data: {purchases: quantity}

            success: (data) ->
                data = JSON.parse data
                if (data.error)
                    console.log data.error
                    $('#alert #content').text(data.error)
                    $('#alert').addClass('alert')
                    $('#alert').alert()
                    $('#alert').show()
                    $('#purchase').removeAttr('disabled')
                else
                    document.location = data.url

            error: (XMLHttpRequest, textStatus, errorThrown) ->
                alert ["/icecream/products", textStatus, textStatus, errorThrown]
        )
    $('#alert').hide()

