table 80005 "PC Purchase Corrections"
{
    fields
    {
        field(10;ID; Integer)
        {
            AutoIncrement = true;
            Editable = false;
        }
        field(20;User; Code[50])
        {
            Editable = false;
        }
        field(30;"PO"; Code[20])
        {
            Editable = false;
        } 
        field(40;"SKU"; Code[20])
        {
            Editable = false;
        }
        field(50;Description; text[100])
        {
            Editable = false;

        }
        field(60;"Original Order Qty"; Decimal)
        {
            Editable = false;
        }
        field(70;"Fulfilo Corrected Qty"; Decimal)
        {
            Editable = false;
        } 
        field(80;"Correction Status";option)
        {
            OptionMembers = Unchanged,Corrected,"Not Ordered","Unknown SKU";
            Editable = false;
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