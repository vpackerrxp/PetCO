tableextension  80012 "PC G/L Accounts Ext" extends "G/L Account" 
{
    fields
    {
        Field(80000;"Rebate Balance";Decimal)
        {
            ObsoleteState = Removed;
            AutoFormatType = 1;
            CalcFormula = Sum ("G/L Entry".Amount WHERE("G/L Account No." = FIELD("No."),
                                                        "G/L Account No." = FIELD(FILTER(Totaling)),
                                                        "Dimension Set ID" = FIELD("Dimension Set ID Filter"),
                                                        Adjustment = Const(False)));
            Caption = 'Rebate Balance';
            Editable = false;
            FieldClass = FlowField;
        } 
    }
    
}