tableextension 80004 "PC Sales Invoice Line Ext"  extends "Sales Invoice Line"
{
    fields
    {
        field(80000; "Shopify Order ID"; biginteger)
        {
            Editable = false;
        }
        field(80001; "Shopify Application ID"; integer)
        {
            Editable = false;
        }
        field(80002;"Bundle Item No.";Code[20])
        {
            Editable = false;
        }
        field(80003;"Bundle Order Qty";Decimal)
        {
            Editable = false;
        }
        field(80004;"Bundle Unit Price";Decimal)
        {
            Editable = false;
        }
        field(80006;"Palatability Status";Option)
        {
            OptionMembers = Unclaimed,Claimed;
            Editable = false;
        }
        field(80007;"Auto Delivered";boolean)
        {
           Editable = false;
        }
        field(80008;"Rebate Supplier No.";Code[20])
        {
           Editable = false;
        }
        field(80009;"Rebate Brand";Code[30])
        {
           Editable = false;
        }
        field(80010; "Shopify Order No"; biginteger)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("PC Shopify Order Header"."Shopify Order No."
                        WHERE ("Shopify Order ID"=field("Shopify Order ID")));
            Editable = false;
        }
          field(80100;"Supplier No.";Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item."Vendor No."
                          WHERE ("No."=FIELD("No.")));
            Editable = false;
        }
        field(80101;"Brand";Code[30])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Brand
                          WHERE ("No."=FIELD("No.")));
            Editable = false;
        }
    }
    keys
    {
        key(Key4; "Shopify Order ID")
        {
        }
    }       
}