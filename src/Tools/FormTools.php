<?php
//
// src/Tools/FormTools.php
//
namespace Praticom\Tools;
//
class FormTools {
	//
	private $name;
	private $label;
	private $attr;
	private $value;
	private $cnn;
	//
	public function __construct($cnn,$name,$label,$attr,$value=''){
		//
		$this->name  = $name;
		$this->label = $label;
		$this->attr  = $attr;
		$this->value = $value;
		$this->cnn 	 = $cnn;
		//
		switch($attr->type){
			//
			case 'hidden': 		echo $this->getHidden(); 		break;
			case 'select': 		echo $this->getSelect(); 		break;
			//case 'number': 		return $this->getNumber(); 		break;
			//case 'calendar': 	return $this->getText();		break;
			//case 'textarea': 	return $this->getTextArea();	break;
			//case 'check': 		return $this->getCheck(); 		break;
			//case 'diffNumber': 	return $this->getDiffNumber(); 	break;
			//case 'button': 		return $this->getButton(); 		break;
			//case 'currency': 	return $this->getCurrency(); 	break;
			//case 'label': 		return $this->getLabel(); 		break;
			default: 			echo $this->getText();
		}
	}	
	//
	private function getHidden(){
		//
		$defaultVal = 	!isset($this->attr->defaultVal) ? '' : $this->attr->defaultVal;
		$value = 		!isset($this->value) ? $defaultVal : $this->value;
		/*
		switch($defaultVal){
			case 'id_user':  $defaultVal = SELF::$user->userConfig['id']; break;
			case 'id_brand': $defaultVal = SELF::$user->brandConfig['id']; break;
		}
		*/
		//
		return '<input type="hidden" name="'.$this->name.'" id="'.$this->name.'" defaultVal="'.$defaultVal.'" value="'.$value.'">';
	}
	//
	private function getText(){
		//
		$required = $this->attr->required ? 'required' : '';
		$response = '<div class="input-group mb-3">';
		$response.= '<input type="'.$this->attr->type.'" class="form-control" name="'.$this->name.'" id="'.$this->name.'" value="'.$this->value.'" placeholder="'.$this->label.'" '.$required.'>';
		$response.= '<div class="input-group-append">';
		$response.= '<div class="input-group-text">';
		$response.= '<span class="fa '.$this->attr->icon.'"></span>';
		$response.= '</div>';
		$response.= '</div>';
		$response.= '</div>';
		//
		return $response;
	}
	//
	private function getSelect(){
		//
		$options = '';
		if($this->attr->parameters){
			if(isset($this->attr->parameters->reference)){
				//
				$res = $this->cnn->doQuery("SELECT * FROM ".$this->attr->parameters->reference." WHERE cd_status = 1");
				//
				if(!$res['success']){
					return $res;
				}
				else{
					//
					foreach($res['fetch'] as $attr){
						$options.='<option value="'.$attr['id'].'">'.$attr['name'].'</option>';
					}
				}
			}
			else if(isset($this->attr->parameters->selectValues)){
				$values = $this->attr->parameters->selectValues;
				//
				foreach($values as $key=>$value){
					$options.='<option value="'.$key.'">'.$value.'</option>';
				}
			}
		}
		else{
			return [
				'success'       => false,
	            'code'          => 400,
	            'msg'           => ERROR_MSG,
	            'error_details' => 'Não há parametros para preencher o select ('.$this->label.')',
	            'parameters'    => []
			];
		}
		//
		$required = $this->attr->required ? 'required' : '';
		$response = '<div class="input-group mb-3">';
		//$response.= '<input type="'.$this->attr->type.'" class="form-control" name="'.$this->name.'" id="'.$this->name.'" value="'.$this->value.'" placeholder="'.$this->label.'" '.$required.'>';
		$response.= '<select name="'.$this->name.'" id="'.$this->name.'" class="form-select" placeholder="'.$this->label.'" '.$required.'>';
		//
		$response.= '<option value="">'.$this->label.'</option>';
		$response.= $options;
		//		
		$response.= '</select>';
		$response.= '<div class="input-group-append">';
		$response.= '<div class="input-group-text">';
		$response.= '<span class="fa '.$this->attr->icon.'"></span>';
		$response.= '</div>';
		$response.= '</div>';
		$response.= '</div>';
        //          
		return $response;                  
	}
	//	
	private function getButton(){
		//
		/*
		$response = '<div class="form-group mb-3">';
		$response.= '<input type="button" class="form-control btn-'.$attr['inputClass'].'" plugin="'.$attr['plugin'].'" name="'.$name.'" id="'.$name.'" value="'.$attr['label'].'">';
		$response.= '</div>'; 
		//
		return $response;
		*/
	}
	//

	private function getNumber(){
		//
		/*
		$required = $attr['required'] ? 'required' : '';
		$response = '<div class="form-group">';
		$response.= '<div class="input-group">';
		$response.= '<div class="input-group-prepend"><span class="input-group-text">'.$attr['label'].'</span></div>';
		$response.= '<button type="button" class="btn btn-primary" name="form_btn_minus"><i class="fa fa-minus"></i></button>';
		$response.= '<input type="number" class="form-control" name="'.$name.'" id="'.$name.'" value="'.$value.'" style="text-align: center" min="'.$attr['min'].'" max="'.$attr['max'].'" placeholder="'.$attr['label'].'" '.$required.'>';
		$response.= '<button type="button" class="btn btn-primary" name="form_btn_plus"><i class="fa fa-plus"></i></button>';
		$response.= '</div>'; 
		$response.= '</div>'; 
		//
		return $response;
		*/
	}
	//
	private function getTextArea(){
		//
		/*
		$icon 	  = isset($attr['icon']) ? '<i class="'.$attr['icon'].'"></i> ' : '';
		$required = $attr['required'] ? 'required' : '';
		$response = '<div class="form-floating mb-3">';
		$response.= '<textarea class="form-control" name="'.$name.'" id="'.$name.'" value="'.$value.'" style="height: 100px" placeholder="'.$attr['label'].'" '.$required.'></textarea>';
		$response.= '<label for="'.$name.'">'.$icon.' '.$attr['label'].'</label>';
		$response.= '</div>'; 
		//
		return $response;
		*/
	}
	//
	private function getCheck(){
		//
		/*
		$response = '';
		$required = !$attr['required'] ? '' : 'required';
		//
		$off = !$attr['off'] ? 'Não' : $attr['off'];
		$on  = !$attr['on']  ? 'Sim' : $attr['on'];
		//
		$off = 'data-off-text="'.$off.'" data-off-color="danger"';
		$on  = 'data-on-text="'.$on.'" data-on-color="success"';
		//
		if(isset($attr['eventChange'])){
			//
			foreach($attr['eventChange'] as $key=>$arg){
				$response.= '<input type="hidden" data-reference="'.$name.'" data-name="eventChange" data-key="'.$key.'" data-on="'.$arg['on'].'" data-off="'.$arg['off'].'"/>';
			}
		}
		//
		if(isset($attr['defaultVal']) && $value == ''){
			$checked 	= $attr['defaultVal'] ? 'checked' : '';	
			$defaultVal = $checked;
		}
		else{
			$checked 	= $value == 1 ? 'checked' : '';	
			$defaultVal = '';
		}
		//
		$response.= '<div class="form-floating mb-3">';
		$response.= '<input type="checkbox" name="'.$name.'" defaultVal="'.$defaultVal.'" data-bootstrap-switch="" data-size="small" '.$off.' '.$on.' '.$required.' '.$checked.' />';
		$response.= '&nbsp;&nbsp;<span>' . $attr['label'] . '</span>';
		$response.= '</div>'; 
		//
		return $response;
		*/
	}
	//
	private function getDiffNumber(){
		//
		/*
		$response = '<div class="form-floating mb-3">';
		$response.= '<input type="'.$attr['input'].'" class="form-control" name="'.$name.'" id="'.$name.'" value="'.$value.'" targets="'.$attr['targets'].'" placeholder="'.$attr['label'].'" disabled>';
		$response.= '<label for="'.$name.'">'.$attr['label'].'</label>';
		$response.= '</div>'; 
		//
		return $response;
		*/
	}
}


?>