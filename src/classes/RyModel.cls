public with sharing class RyModel {
	
	public class SchemaNode {
		
		public Boolean type_from_sObject;
		public String sf_field;
		
		public SchemaNode(String sf_field) {
			this.type_from_sObject = true;
			this.sf_field = sf_field;
		}
		
	}
	
	public class SubmittedValue {
		public String value;
	}
	
	public class SubmittedModel {
		public map<string, string> attributes;
		
		public SubmittedModel() {
			this.attributes = new map<string, string>();
		}
	}
	
	public class ObjType {
		public map<string, string> attributes;
	}
	
	public class ModelSchema {
		
		private Map<String, SchemaNode> nodes;
		public String sf_object;
		
		public ModelSchema() {
			this.nodes = new Map<String, SchemaNode>();
		}
		
		public void addNode(String key, SchemaNode node) {
			this.nodes.put(key, node);
		}
		
		public void addNode(SchemaNode node) {
			this.nodes.put(node.sf_field, node);
		}
		
		public Map<String, SchemaNode> getNodes() {
			return this.nodes;
		}
	}
	
	
	public class ProcessedResponse {
		
		public sObject obj;
		public Boolean success;
		public map<string,string> errors;
		
	}
	
	
	public static sObject processModel(map<string, string> model, ModelSchema model_schema) {
		
		ProcessedResponse response = new ProcessedResponse();
		
		map<string, string> clean_model = new map<string, string>();
		
		for (String k : model.keySet()) {
			String value = model.get(k);
			
			if (k == 'id') {
				clean_model.put('id',value);
			}
			
			String field;
			if (model_schema.getNodes().containsKey(k)) {
				field = model_schema.getNodes().get(k).sf_field;
				clean_model.put(field, value);
			}
			
		}
		
		if (!clean_model.isEmpty()) {
			
			Schema.sObjectType targetType = Schema.getGlobalDescribe().get(model_schema.sf_object);
	        sObject sf_obj = targetType.newsObject();
			
			for (String field_name : clean_model.keySet()) {
				String field_type = getFieldType(model_schema.sf_object, field_name);
				sf_obj = setValue(clean_model.get(field_name), field_name, sf_obj);
			}
						
			try {
				upsert sf_obj;
				
				
			} catch (exception e) {
				// TODO: do something
			}
			return sf_obj;
		}
		return null;
	}
	
	public static string castValue(String value, String field_name, sObject sf_obj) {
		String sobject_name = sf_obj.getSObjectType().getDescribe().getName();
		return castValue(value, field_name, sobject_name);
	}
	
	public static string castValue(String value, String field_name, String sobject_name) {
		
		String field_type = getFieldType(sobject_name, field_name);
		
		Set<String> strings = new Set<String> {
			'STRING',
			'PHONE',
			'PICKLIST',
			'MULTIPICKLIST',
			'TEXTAREA',
			'EMAIL',
			'ENCRYPTEDSTRING',
			'ID',
			'REFERENCE',
			'URL'
		};
		
		Set<String> decimals = new Set<String> {
			'CURRENCY',
			'PERCENT',
			'DOUBLE'
		};
		
		if (strings.contains(field_type)) {
			return 'text';
		} else if (decimals.contains(field_type)) {
			return 'decimal';
		} else if (field_type == 'INTEGER') {
			return 'number';
		} else if (field_type == 'DATE') {
			return 'date';
		}
		
		return null;
	}
	
	
	private static sObject setValue(String value, String field_name, sObject sf_obj) {
		
		String casted = RyModel.castValue(value, field_name, sf_obj);
		
		if (casted == 'text') {
			sf_obj.put(field_name, String.valueOf(value));
		} else if (casted == 'decimal') {
			sf_obj.put(field_name, Decimal.valueOf(value));
		} else if (casted == 'number') {
			sf_obj.put(field_name, Integer.valueOf(value));
		} else if (casted == 'date') {
			sf_obj.put(field_name, Date.valueOf(value));
		}
		
		return sf_obj;
		
	}
	
	
	private static String getFieldType(String sobject_name, String field_name) {
		String field_type = '';
		try {
			field_type = Schema.getGlobalDescribe().get(sobject_name).getDescribe().fields.getMap().get(field_name).getDescribe().getType().name();
		} catch (Exception e) {
			// TODO: do something
		}
		return field_type;
	}
	
	

}