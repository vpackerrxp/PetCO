table 80028 "PC EDI Execution Log"
{
    Caption = 'PC EDI Execution Log';
    
    fields
    {
        field(10; ID; Integer)
        {
            AutoIncrement = true;
        }
        field(20;"Execution Date/Time"; Datetime)
        {
            Editable = false;
        }
        field(30;"Purchase Order No."; Code[20])
        {
            Editable = false;
        }
        field(40;Vendor; Code[20])
        {
            Editable = false;
        }
        field(50;"Vendor Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field(Vendor)));
        }
        field(60;"EDI Execution Action";Option)
        {
            OptionMembers = ,Response,Dispatch,Invoice,CreditNote,Inventory;
            Editable = false;
        }
        field(70;"Transaction Status";option)
        {
            Editable = false;
            OptionMembers = " ",ORIGINAL,REPLACE,CANCEL;
        }
      
   }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
    
}
