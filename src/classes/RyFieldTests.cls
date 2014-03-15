@isTest
public class RyFieldTests {
    
    /* Tests */
    
    @isTest
    static void test_setup() {
        RyField field = new RyField();
        
        system.assert(field.widget.field == field);
    }

    @isTest
    static void test_name() {
        RyField field = new RyField();
        field.name = 'email';
        field.namespace = 'person';
        field.suffix = '1';

        system.assertEquals('person-email--1',field.renderedName);
    }

    @isTest
    static void test_setupValidators() {

        RyField field = new RyField();
        field.name = 'Name';

        field.setup();
        field.setupValidators();

        system.assert(field.widget.validatorCss.contains('required'));

    }
    
    @isTest
    static void test_setupWidget() {
        RyField field = new RyField();
        
        field.widget.type = 'Text';
        
        field.setupWidget();
        
        // Render the widget and make sure it is not the default
        system.assert(field.widget.render().contains('<textarea'));
    }
    
    @isTest
    static void test_render() {
        RyField field = new RyField();
        field.name = 'spam';
        field.label = 'Test';
        field.description = 'A test field.';
        field.defaultValue = 'value';
        field.error = 'Oh no!';
        
        String rendered = field.rendered;
        
        system.assert(rendered.contains('spam'));
        system.assert(rendered.contains('Test'));
        system.assert(rendered.contains('A test field.'));
        system.assert(rendered.contains('value'));
        system.assert(rendered.contains('Oh no!'));
    }
}