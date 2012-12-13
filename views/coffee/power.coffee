jQuery ->
    $('form#add-product-form').ajaxForm
        beforeSubmit: (arr, $form, options) =>
            $('button:submit').button('loading')
            true
        success: (data) =>
            data = JSON.parse data
            $('button:submit').data('loading-text', 'Complete!')
            $('#public_url').html("<a href='/?#{data.public_link_id}'>http://power.com/?#{data.public_link_id}</a>")
            $('#status_url').html("<a href='/products/?#{data._id}'>http://power.com/products/?#{data._id}</a>")

            $('.result').html("<p>Your Power! page: <a href='/?#{data.public_link_id}'>http://power.com/?#{data.public_link_id}</a></p><p>Your Power! manageemnt page: <a href='/products/?#{data._id}'>http://power.com/products/?#{data._id}</a></p>")
            $('#submitModal').reveal(animation: 'fade')
        error: (XMLHttpRequest, textStatus, errorThrown) ->
            alert ["/icecream/products", textStatus, textStatus, errorThrown]

    $('input[name*="unit_price"]').popover(
        title: "Reminder"
        content: "The price you put in will have to include shipping cost"
        trigger: "focus"
    )

    $('input[name*="unit_price"]').keyup( ->
        if $(this).val() != ""
            value = $(this).val()
            $.get('/listing_price', {price: value}, (data) ->
                data = JSON.parse data
                $('#listing_price').text(data.price)
            )
        else
            $('#listing_price').text("0.00")
    )

    $('button:submit').button()
