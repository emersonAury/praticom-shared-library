// resources/_js/alert.js
//
export function loadAlert(div){
    //
    console.log("#####    alert.js module is loaded");
    console.log("*****    Alert Div reference $('"+div+"')");
    //
    $(div).prepend('<div id="main-alert" class="alert-fixed" role="alert"></div>');
}
//
export function showAlert(response, modal = "#main-alert") {
    // Esconde qualquer alerta anterior no mesmo container
    hideAlert(modal, response);

    if (response.success) {
        $(modal).addClass('alert alert-success show').html('<i class="fa fa-check"></i>&nbsp;&nbsp;' + response.msg);
        if (response.element) {
            $(':input[name="' + response.element + '"][data-id="' + response.id + '"]').addClass('is-valid');
        }
    } 
    else {
        const errorDetails = response.error_details ? `<br/><small>${response.error_details}</small>` : '';
        $(modal).addClass('alert alert-danger show').html('<i class="fa fa-ban"></i>&nbsp;&nbsp;<b>' + response.msg + '</b>' + errorDetails);
        if (response.element) {
            $(':input[name="' + response.element + '"][data-id="' + response.id + '"]').addClass('is-invalid');
        }
    }
}
//
export function hideAlertAfter(delay = 3000, modal = "#main-alert", response = null) {
    setTimeout(function() {
        hideAlert(modal, response);
    }, delay);
}
//
export function hideAlert(modal = "#main-alert", response = null) {
    $(modal).removeClass('show alert-success alert-danger').addClass('hide').html('');
    if (response && response.element) {
        $(':input[name="' + response.element + '"][data-id="' + response.id + '"]').removeClass('is-valid is-invalid');
    }
}