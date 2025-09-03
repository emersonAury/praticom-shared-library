'use strict';
//
var dir = "api/"+api+"/backEnd/";
var errors = [];
//
$(function(){
	//
	console.log("Inicio do default.js");
})
//
function getAjax(dataObj,ajaxFile,responseFunction){
	//
	console.log(dataObj);
	//
	$.ajax({
		type: 		"POST",
		dataType: 	"json",
		url: 		dir+ajaxFile+".php",
		data: 		{
			'sector' : 			sector,
      		'responseFunction': responseFunction,
      		'dataObj':    		dataObj,
		}
		//
	}).fail(function(xhr, textStatus, error){
		var response = {
			success: false, 
			code: xhr.status, 
			error_details: !xhr.responseText ? 'Servidor não retornou dados' : xhr.responseText,
			msg: "A requisição falhou",
			parameters: []
		};
		window[responseFunction](response);
		//
	}).done(function(response){
		console.log(response);
		window[responseFunction](response);
	});
}
//
function validationAndSubmit(ajaxFile,responseFunction){
	//
	hideAlert(null, $('form :input'));
	//
	var dataObj = getFormFields();
	//
	if(dataObj){
		getAjax(dataObj,ajaxFile,responseFunction);
	}
}
//
function getFormFields(){
	//
	var inputs = [];
	var error = false;
	errors = [];
	//
	$('form :input').each(function(i,v){
		//
		if($(this).attr('name')){
	  		//
		  	var type  	 = !$(this).attr('type') ? $(this)[0].localName : $(this).attr('type');
		  	var required = !$(this).attr('required') ? false : true;
		  	var name  	 = $(this).attr('name');
		  	var value 	 = $(this).val();
		  	//
		  	if(type == 'calendar'){
		  		value = !value ? null : formatDateToDB(value);
		  	}
		  	//
		  	if(type == 'checkbox'){
		  		value = $(this).bootstrapSwitch('state') ? 1 : 0;
		  	}
		  	//
		  	if(required && !value){
				$(this).addClass('is-invalid');
				error = true;
			}
			else{
				$(this).removeClass('is-invalid');
			}
			//
			if(type != "button"){
			  	inputs.push({
			  		'name': name, 
			  		'type': type, 
			  		'required': required, 
			  		'value': value
			  	});
			}
	  	}
	});
	//
	if(error){
	  	showAlert({success: false, msg: 'Não foram preenchido campos obrigatórios'});
		return false;
	}
	//
	return inputs;
}
//
//////////////////////////////////////////////////////////////////
// ALERT FUNCTIONS
//////////////////////////////////////////////////////////////////
function showAlert(response, modal = "#main-alert"){
	//
	hideAlert(modal,response);
	//
	if(response.success){
		//
		$(modal).addClass('alert alert-success show').html('<i class="fa fa-check"></i>&nbsp;&nbsp;' + response.msg);
		//
		if(response.element){
			$(':input[name="'+response.element+'"][data-id="'+response.id+'"]').addClass('is-valid');	
		}
	}
	else{
		//
		$(modal).addClass('alert alert-danger show').html('<i class="fa fa-ban"></i>&nbsp;&nbsp;<b>' + response.msg + '</b><br/>' + (!response.error_details ? '' : response.error_details));
		//
		if(response.element){
			$(':input[name="'+response.element+'"][data-id="'+response.id+'"]').addClass('is-invalid');
		}
	}
}
//
function hideAlertAfter(delay = 2000, modal = "#main-alert", response = null){
	//
	setTimeout(function(){
		hideAlert(modal,response);
	},delay);
}
//
function hideAlert(modal = "#main-alert", response = null){
	//
	$(modal).removeClass('show').removeClass('alert-success').removeClass('alert-danger').removeClass('alert').addClass('hide').html('');
	//
	if(response){
		$(':input[name="'+response.element+'"][data-id="'+response.id+'"]').removeClass('is-valid').removeClass('is-invalid');
	}
}
//