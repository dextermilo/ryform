public class RySubForm extends RyForm {

    public RyField parentField { get; set; }

    public String namespace {
        get {
            if (this.parentField != null) {
                return this.parentField.renderedName;
            }
            return '';
        }
    }

}