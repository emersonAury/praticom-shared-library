// resources/_js/alert.js
//
window.PraticomUI = window.PraticomUI || {};
//
PraticomUI.alerts = {
    //
    load: function(div) {
        console.log("#####    alert.js module is loaded");
        //
        if(div){
            console.log("*****    Alert Div reference $('"+div+"')");
        }
        else{
            console.log("*****    Alert Div reference not provided, using body");
            div = 'body';
        }
        //
        $(div).prepend('<div id="main-alert" class="alert-fixed" role="alert"></div>');
    },
    //
    show: function(response, modal = "#main-alert") { 
        // Esconde qualquer alerta anterior no mesmo container
        this.hideAlert(modal, response);
        // Mostra o novo alerta
        if (response.success) {
            $(modal).addClass('alert alert-success show')
            .html('<i class="fa fa-check"></i>&nbsp;&nbsp;' + response.msg);
            //
            if (response.element) {
                $(':input[name="' + response.element + '"][data-id="' + response.id + '"]')
                .addClass('is-valid');
            }
        } 
        else {
            //
            $(modal).addClass('alert alert-danger show')
            .html('<i class="fa fa-ban"></i>&nbsp;&nbsp;<b>' + response.msg + '</b>' + errorDetails);
            //
            if (response.element) {
                $(':input[name="' + response.element + '"][data-id="' + response.id + '"]').addClass('is-invalid');
            }
        }
    },
    //
    hide: function(response, modal = "#main-alert") { 
        //
        $(modal).removeClass('show alert-success alert-danger').addClass('hide').html('');
        //
        if (response && response.element) {
            $(':input[name="' + response.element + '"][data-id="' + response.id + '"]').removeClass('is-valid is-invalid');
        }
    },
    //
    hideAfter: function(response, modal = "#main-alert", delay = 3000) { 
        setTimeout(function() {
            this.hide(response,modal);
        }, delay);
    } 
};