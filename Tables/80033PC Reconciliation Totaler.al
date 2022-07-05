table 80033 "PC Reconciliation Totaler"
{
    fields
    {
        field(10;"Doc No."; Code[20])
        {
            Caption = 'Doc No.';
            DataClassification = ToBeClassified;
        }
        field(20;"Doc Type"; Option)
        {
            OptionMembers =  Invoice,CreditNote;
        }
        field(30;Total; Decimal)
        {
        }
        field(40;Totaliser; decimal)
        {
        }
    }
    keys
    {
        key(PK; "Doc No.","Doc Type")
        {
            Clustered = true;
        }
    }
}
