public with sharing class RyModelTestController {
	
	public RyForm form { get; set; }
	
	public static RyModel.ModelSchema account_schema { get; set; }
	
	public static RyModel.ModelSchema opp_schema { get; set; }
	
	public map<string,string> params {get;set;}
	
	public string test_json { get; set; }
	
	public string test_nav { get; set; }
	
	public RyModelTestController() {
		
		params = ApexPages.currentPage().getParameters();
		
		account_schema = new RyModel.ModelSchema();
		account_schema.sf_object ='Account';
		account_schema.addNode('name', new RyModel.SchemaNode('Name'));
		account_schema.addNode('revenue', new RyModel.SchemaNode('AnnualRevenue'));
		account_schema.addNode('num_staff', new RyModel.SchemaNode('NumberOfEmployees'));
		account_schema.addNode('phone', new RyModel.SchemaNode('Phone'));
		account_schema.addNode('rating', new RyModel.SchemaNode('Rating'));
		account_schema.addNode('street', new RyModel.SchemaNode('ShippingStreet'));
		account_schema.addNode('url', new RyModel.SchemaNode('Website'));
		account_schema.addNode('text', new RyModel.SchemaNode('Description'));
		account_schema.addNode('parent', new RyModel.SchemaNode('ParentId'));
		
		opp_schema = new RyModel.ModelSchema();
		opp_schema.sf_object ='Opportunity';
		opp_schema.addNode('name', new RyModel.SchemaNode('Name'));
		opp_schema.addNode('stage', new RyModel.SchemaNode('StageName'));
		opp_schema.addNode('close', new RyModel.SchemaNode('CloseDate'));
		
		/*
		form = new RyForm();
		form.params = params;
		form.models.add(account_schema);
		//form.models.add(opp_schema);
		
		// form
		form.field_list.add(
			new RyForm.RyField('{ "name": "name", "label": "Organization Name" }')
			);
		form.field_list.add(
			new RyForm.RyField('{ "name": "revenue", "data_type": "number", "label": "Revenue", "default_value": "1000", "description": "What is the average yearly revenue for this organization?" }')
			);
		form.field_list.add(
			new RyForm.RyField('{ "name": "num_staff", "data_type": "number", "label": "How many employees?", "default_value": "10" }')
			);
		form.field_list.add(
			new RyForm.RyField('{ "name": "phone", "label": "Phone" }')
			);
		form.field_list.add(
			new RyForm.RyField('{ "name": "rating", "label": "Rating" }')
			);
		form.field_list.add(
			new RyForm.RyField('{ "name": "street", "label": "Address" }')
			);
		form.field_list.add(
			new RyForm.RyField('{ "name": "url", "label": "Website URL", "validator": "isURL" }')
			);
			
		RyForm.RyField description = new RyForm.RyField('{ "name": "text", "label": "Description" }');
		description.widget = new RyWidget.Text();
		description.RyField();
		form.field_list.add(description);
		*/
		
		String form_id = params.get('form_id');
		
		Custom_Form__c form_definition = [SELECT Id, Schema__c FROM Custom_Form__c WHERE Id = :form_id];
		form = parseSchema(form_definition.Schema__c);
		form.params = params;
		//form.models.add(account_schema);
		
		
		form.setup();
	   
	}
	
	
	public PageReference submit() {
		
		map<string,string> params = ApexPages.currentPage().getParameters();
		form.params = params;
		form.setup();
		sObject result;
		
		// Validate overall form
		if (form.validate(params)) {
			for (RyModel.ModelSchema s : form.models) {
				result = RyModel.processModel(params, s);
			}
		
			PageReference redirect = new PageReference('/'+result.Id);
			return redirect;
		} else {
			// Render errors
		}
		return null;
		
		
		
	}
	
	public RyForm parseSchema(String schema) {
		
		JSONParser parser = JSON.createParser(schema);
		RyForm temp_form = new RyForm();
		String parsing = '';
		
		while (parser.nextToken() != null) {
			
			/* Parse fields */
			if (parser.getCurrentName() == 'field_list') {
				parsing = 'fields';
			}
			if (parser.getCurrentToken() == JSONToken.START_ARRAY && parsing == 'fields') {
			
				while (parser.nextToken() != null) {
					
					if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
	    
	                    RyForm.RyField field = (RyForm.RyField)parser.readValueAs(RyForm.RyField.class);
	                    field.widgitify();
	                    field.setup();
	    				temp_form.field_list.add(field);
	                    parser.skipChildren();
	                    
	                }
	                
	                if (parser.getCurrentToken() == JSONToken.END_ARRAY) {
	                	
	                	parsing = '';
	                	break;
	                	
	                }
					
				}
				
			}
			
			/* Parse models */
			if (parser.getCurrentName() == 'models') {
				parsing = 'models';
			}
			if (parser.getCurrentToken() == JSONToken.START_ARRAY && parsing == 'models') {
			
				while (parser.nextToken() != null) {
					
					if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
	    
	                    RyModel.ModelSchema model = (RyModel.ModelSchema)parser.readValueAs(RyModel.ModelSchema.class);
	    				temp_form.models.add(model);
	                    parser.skipChildren();
	                    
	                }
	                
	                if (parser.getCurrentToken() == JSONToken.END_ARRAY) {
	                	
	                	parsing = '';
	                	break;
	                	
	                }
					
				}
				
			}
			
			
			
			
		}
		
		return temp_form;
	}
	
	
	public static list<SObject> performSync(list<map<string, string>> models) {
		
		list<SObject> sobs = new list<SObject>();
		
		if (!models.isEmpty()) {
			
			for (map<string, string> model : models) {
				
				sobs.add(RyModel.processModel(model, account_schema));				
				
			}
			
			return sobs;
			
		}
		
		return null;
	}
	
	
	public static SObject performSync(map<string, string> model, String schema_name) {
		
		if (!model.isEmpty()) {
			
			if (schema_name == 'account') {
				return RyModel.processModel(model, account_schema);
			}
			if (schema_name == 'opp') {
				return RyModel.processModel(model, opp_schema);
			}
			
		}
		
		return null;
	}
	
	
	static testMethod void testBase() {
		
		RyModelTestController c = new RyModelTestController();
		
		system.assert(!account_schema.getNodes().isEmpty());
		
		map<string, string> sm = new map<string, string>();
		
		Account parent = new Account(
			Name = 'Test Money'
		);
		insert parent;
		
		sm.put('name', 'ACME Publishing');
		sm.put('revenue', '20000');
		sm.put('num_staff', '2');
		sm.put('phone', '527-4326');
		sm.put('rating', 'Awesome');
		sm.put('street', 'somewhere');
		sm.put('url', 'http://www.yahoo.com');
		sm.put('text', 'Long text\nanother line');
		sm.put('parent', parent.Id);
		
		Account acc = (Account)performSync(sm, 'account');
		
		system.assertNotEquals(acc.Id, null);
		system.assertEquals(acc.Rating, 'Awesome');
		system.assertEquals(acc.ShippingStreet, 'somewhere');
		system.assertEquals(acc.Website, 'http://www.yahoo.com');
		system.assertEquals(acc.Description, 'Long text\nanother line');
		system.assertEquals(acc.ParentId, parent.Id);
		
		map<string, string> om = new map<string, string>();
		
		om.put('name', 'ACME Gift');
		om.put('stage', 'Closed Won');
		om.put('close', String.valueOf(Date.today()));
		
		Opportunity opp = (Opportunity)performSync(om, 'opp');
		system.assertNotEquals(opp.Id, null);
		system.assertEquals(opp.CloseDate, Date.today());
		
	}
}