@isTest
public class RyModelTests {
    /* Tests */
    
    @isTest
    static void test_schemaNode() {
        
        RySchema.Node node = new RySchema.Node('Name');
        //system.assert(node.type_from_sObject);
        
        RySchema.Node node2 = new RySchema.Node();
        //system.assert(node.type_from_sObject);
    }

    @isTest
    static void test_setup_validator() {

        RySchema.Node node = new RySchema.Node('Name');
        node.required = true;

        Boolean req = false;
        Boolean num = false;
        Boolean man = false;
        Boolean email = false;

        node.setupValidators();

        for (RyValidator.Base v : node.ryValidators) {
            if (v.cssClass == 'required') req = true;
        }

        system.assert(req);
        system.assert(node.ryValidators.size() == 1);

        node.dataType = 'number';
        node.max = 10;

        node.setupValidators();

        for (RyValidator.Base v : node.ryValidators) {
            if (v.cssClass == 'number') num = true;
        }

        system.assert(num);

        node.validator = 'isURL';
        node.validators.add('isURL');

        node.setupValidators();

        for (RyValidator.Base v : node.ryValidators) {
            if (v.cssClass == 'url') man = true;
        }
        
        system.assert(man);

        node.addValidator('isEmail');

        node.setupValidators();

        for (RyValidator.Base v : node.ryValidators) {
            if (v.cssClass == 'email') email = true;
        }
        
        system.assert(email);

    }

    @isTest
    static void test_validate() {
        RySchema.Node node = new RySchema.Node('Name');

        node.setupValidators();

        system.assert(node.validate() == '');

        node.required = true;

        node.setupValidators();

        system.assert(node.validate() != '');

        node.currentValue = 'Something';

        system.assert(node.validate() == '');
    }
    
    @isTest
    static void test_modelSchema() {
        
        RySchema.Node node = new RySchema.Node('Name');
        RySchema.Node node2 = new RySchema.Node('Description');
        
        RyModel.ModelSchema model = new RyModel.ModelSchema();
        
        model.addNode(node);
        model.addNode('text', node2);
        model.addNode('AccoundId');
        model.addNode('sf_id', 'Id');
        
        Map<String, RySchema.Node> nodes = model.getNodes();
        
        system.assert(nodes.containsKey('Name'));
        system.assert(nodes.containsKey('text'));
        system.assert(nodes.containsKey('AccoundId'));
        system.assert(nodes.containsKey('sf_id'));
        
    }
    
    @isTest
    static void test_getFieldType() {
        
        String good_field = RyModel.getFieldType('Account', 'Name');
        String bad_field = RyModel.getFieldType('Account', 'asdfas');
        
        System.assertEquals('STRING', good_field);
        System.assertEquals('', bad_field);
        
    }
    
    @isTest
    static void test_castField() {
        
        Account acc = new Account();
        
        String str = RyModel.castField('Name', acc);
        String dec = RyModel.castField('Amount', 'Opportunity');
        String num = RyModel.castField('NumberOfEmployees', 'Account');
        String dt = RyModel.castField('CloseDate', 'Opportunity');
        String bogus = RyModel.castField('not a real field', 'Opportunity');
        
        system.assertEquals('text', str);
        system.assertEquals('decimal', dec);
        system.assertEquals('number', num);
        system.assertEquals('date', dt);
        
    }
    
    @isTest
    static void test_setValue() {
        
        Account acc = new Account();
        Opportunity opp = new Opportunity();
        
        RyModel.setValue('Test Name', 'Name', acc);
        RyModel.setValue('100', 'Amount', opp);
        RyModel.setValue('2', 'NumberOfEmployees', acc);
        RyModel.setValue('2012-01-01', 'CloseDate', opp);
        
        system.assertEquals('Test Name', acc.Name);
        system.assertEquals(100, opp.Amount);
        system.assertEquals(2, acc.NumberOfEmployees);
        system.assertEquals(Date.valueOf('2012-01-01'), opp.CloseDate);
        
    }
    
    @isTest
    static void test_processModel() {
        
        RySchema.Node node = new RySchema.Node('Name');
        RySchema.Node node2 = new RySchema.Node('Description');
        RySchema.Node node3 = new RySchema.Node('NumberOfEmployees');
        RySchema.Node node4 = new RySchema.Node('Id');
        
        RyModel.ModelSchema model = new RyModel.ModelSchema();

        RyModel.ProcessedResponse response;
        
        model.addNode(node);
        model.addNode('text', node2);
        model.addNode('employee_count', node3);
        
        Map<String, String> params = new Map<String, String>();
        params.put('Name', 'Test Name');
        params.put('text', 'A really good test company.');
        params.put('employee_count', '10');

        // Test null sfObject first
        response = RyModel.processModel(params, model);
        system.assert(response.error.contains('ModelSchema.sfObject'));

        model.sfObject = 'Account';

        // Dry-run
        model.action = 'return';
        response = RyModel.processModel(params, model);
        system.assert(response.obj.get('Id') == null);
        
        // Upsert
        model.action = 'upsert';
        response = RyModel.processModel(params, model);
        
        Account acc = [SELECT Name, Description, NumberOfEmployees FROM Account WHERE Name = 'Test Name'];
        
        system.assert(response.success);
        system.assertEquals('Test Name', acc.Name);
        system.assertEquals('A really good test company.', acc.Description);
        system.assertEquals(10, acc.NumberOfEmployees);

        // Update
        model.action = 'insert';
        params.put('Name', 'Test Name2');
        
        response = RyModel.processModel(params, model);
        
        acc = [SELECT Name, Description, NumberOfEmployees FROM Account WHERE Name = 'Test Name2'];
        
        system.assert(response.success);
        
        // Update
        params.put('Id', acc.Id);
        model.addNode(node4);
        params.put('employee_count', '15');
        model.action = 'update';
        
        response = RyModel.processModel(params, model);
        
        acc = [SELECT Name, Description, NumberOfEmployees FROM Account WHERE Id = :acc.Id];
        
        system.assert(response.success);
        system.assertEquals(15, acc.NumberOfEmployees);
        
        // Fail with non-number
        params.put('employee_count', 'abc');
        model.action = null;
        
        response = RyModel.processModel(params, model);
        
        acc = [SELECT Name, Description, NumberOfEmployees FROM Account WHERE Id = :acc.Id];
        
        system.assert(!response.success);
        system.assertEquals(15, acc.NumberOfEmployees);
        
        // Fail with validation error
        params.put('employee_count', '123456789');
        
        response = RyModel.processModel(params, model);
        
        acc = [SELECT Name, Description, NumberOfEmployees FROM Account WHERE Id = :acc.Id];
        
        system.assert(!response.success);
        system.assertEquals(15, acc.NumberOfEmployees);
        
        // Fail with no matching input
        params.clear();
        params.put('fake','nothing');
        response = RyModel.processModel(params, model);
        system.assert(response == null);
    }

    @isTest
    static void test_process_objectmap() {

        RySchema.Node node = new RySchema.Node('Name');
        RySchema.Node node2 = new RySchema.Node('Description');
        RySchema.Node node3 = new RySchema.Node('NumberOfEmployees');
        RySchema.Node node4 = new RySchema.Node('Id');
        
        RyModel.ModelSchema model = new RyModel.ModelSchema();

        RyModel.ProcessedResponse response;
        
        model.sfObject = 'Account';
        model.addNode(node);
        model.addNode('text', node2);
        model.addNode('employee_count', node3);
        
        Map<String, String> params = new Map<String, String>();
        params.put('Name', 'Test Name');
        params.put('text', 'A really good test company.');
        params.put('employee_count', '10');

        Map<String, Object> obj_params = (Map<String, Object>)params;

        response = RyModel.processModel(obj_params, model);

        system.assert(response.success);

    }

    @isTest
    static void test_getObjQuery() {

        RySchema.Node node = new RySchema.Node('Name');
        RySchema.Node node2 = new RySchema.Node('Description');
        RySchema.Node node3 = new RySchema.Node('NumberOfEmployees');
        
        RyModel.ModelSchema model = new RyModel.ModelSchema();

        RyModel.ProcessedResponse response;
        
        model.sfObject = 'Account';
        model.addNode(node);
        model.addNode('text', node2);
        model.addNode('employee_count', node3);

        String query = RyModel.getObjQuery(model);

        system.assert(query.contains('Name'));
        system.assert(query.contains('Description'));
        system.assert(query.contains('NumberOfEmployees'));

    }

}