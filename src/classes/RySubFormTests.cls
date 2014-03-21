@isTest
public class RySubFormTests {

    /* Tests */

    @isTest
    static void test_subform() {

        RySubForm subform = new RySubForm();

        RyForm.Field fld = new RyForm.Field();
        fld.name = 'test';

        system.assertEquals('', subform.namespace);

        subform.parentField = fld;

        system.assertEquals(fld.name, subform.namespace);

    }

}