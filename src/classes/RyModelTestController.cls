public with sharing class RyModelTestController {
    
    public RyForm form { get; set; }
    
    public static RyModel.ModelSchema account_schema { get; set; }
    
    public static RyModel.ModelSchema opp_schema { get; set; }
    
    public Map<String, String> params {get;set;}
    
    public String test_json { get; set; }
    
    public String test_nav { get; set; }
    
    public RyModelTestController() {
        
        params = ApexPages.currentPage().getParameters();
        
        String form_id = params.get('form_id');
        
        Custom_Form__c form_definition = [SELECT Id, Schema__c FROM Custom_Form__c WHERE Id = :form_id];
        form = RyFormParser.parse(form_definition.Schema__c);
        form.params = params;
        
        RyForm.Field list_field = new RyForm.Field();
        list_field.name = 'list';
        list_field.label = 'People';

        RySubForm list_form = new RySubForm();

        RyForm.Field sub_field = new RyForm.Field();
        sub_field.name = 'person';
        sub_field.label = 'Person';
        list_form.addField(sub_field);

        RyForm.Field sub_field2 = new RyForm.Field();
        sub_field2.name = 'age';
        sub_field2.label = 'Age';
        list_form.addField(sub_field2);

        RyForm.Field sub_field3 = new RyForm.Field();
        sub_field3.name = 'bio';
        sub_field3.label = 'Bio';
        sub_field3.widget = new RyWidget.Text();
        sub_field3.setup();
        list_form.addField(sub_field3);

        list_field.widget = new RyWidget.ObjectList();
        list_field.widget.schema = list_form;
        list_field.widget.setup();
        list_field.setup();

        form.addField(list_field);

        form.setup();
       
    }
    
    
    public PageReference submit() {
        
        Map<String, String> params = ApexPages.currentPage().getParameters();
        form.params = params;
        form.setup();
        RyModel.ProcessedResponse result;
        
        // Validate overall form
        if (form.validate()) {
            for (RyModel.ModelSchema s : form.models) {
                result = RyModel.processModel(params, s);
            }
        
            PageReference redirect = new PageReference('/'+result.obj.get('Id'));
            return redirect;
        } else {
            // Render errors
        }
        return null;
        
        
        
    }
    
    
    
    
}