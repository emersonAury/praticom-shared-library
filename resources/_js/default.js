'use strict';
//
// resources/_js/default.js
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