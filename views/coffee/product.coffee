jQuery ->
    $('#plus').click (e) =>
        quantity = parseInt($('#quantity').text(), 10) + 1
        $('#quantity').html(quantity)

    $('#minus').click (e) =>
        quantity = parseInt($('#quantity').text(), 10) - 1
        if quantity > 0
            $('#quantity').html(quantity)

    $('#purchase').click (e) =>
        quantity = parseInt($('#quantity').text(), 10)
        product_id = $('.product-showcase').data('product-id')
        $.ajax(
            type: "GET"
            url: "/orders/create/" + product_id
            data: {purchases: quantity}
            async: true
            cache: false
            timeout: 50000
        )
