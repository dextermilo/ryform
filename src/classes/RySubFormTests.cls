@isTest
public class RySubFormTests {

    /* Tests */

    @isTest
    static void test_subform() {

        RySubForm subform = new RySubForm();

        RyField fld = new RyField();
        fld.name = 'test';

        system.assertEquals('', subform.namespace);

        subform.parentField = fld;

        system.assertEquals(fld.name, subform.namespace);

    }

}