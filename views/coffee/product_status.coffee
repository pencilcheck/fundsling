jQuery ->
    $('a[href*="#charge-and-ship"]').click (e) ->
        $('#charge-and-ship').attr('disabled', 'disabled')


    $('#charge-and-ship-modal').on('show', ->
        construct_dialog()
    )

    construct_dialog = () ->
        product_id = $('.product-showcase').data('product-id')
        $.ajax(
            type: "POST"
            url: "/orders/products/" + product_id

            success: (data) ->
                console.log data
                data = JSON.parse data
                if (data.error)
                    console.log data.error
                    $('#alert #content').text(data.error)
                    $('#alert').addClass('alert')
                    $('#alert').alert()
                    $('#alert').show()
                    $('#charge-and-ship').removeAttr('disabled')
                    $('#charge-and-ship-modal').modal('hide')
                else
                    product_id = $('.product-showcase').data('product-id')
                    if data.length == 0
                        $('#charge-and-ship-modal .modal-body').html('<h1>No orders</h1>')
                    else
                        dust.render '/dust/charge_and_ship_form_template', {orders: data, product_id: product_id}, (err, out) ->
                            $('#charge-and-ship-modal .modal-body').html(out)
                            $('#charge_and_ship_form').ajaxForm
                                success: (data) ->
                                    data = JSON.parse data
                                    if (data.error)
                                        console.log data.error
                                        $('#alert #content').text(data.error)
                                        $('#alert').addClass('alert')
                                        $('#alert').alert()
                                        $('#alert').show()
                                        $('#charge-and-ship').removeAttr('disabled')
                                        $('#charge-and-ship-modal').modal('hide')
                                    else
                                        $('#charge-and-ship').val('Done')
                                        # reveal a thank you dialog here
                                        $('#thankyouModal').reveal(animation: 'fade')

                                error: (XMLHttpRequest, textStatus, errorThrown) ->
                                    alert ["/chargeandship", textStatus, textStatus, errorThrown]

            error: (XMLHttpRequest, textStatus, errorThrown) ->
                alert ["/orders/products", textStatus, textStatus, errorThrown]
        )

    $('#alert').hide()
