table 80012 "PC Shopify Discount Apps"
{
    ObsoleteState = removed;
    fields
    {
        field(10;"Shopify Discount App Type";Option)
        {
            OptionMembers = manual,automatic,script,discount_code;
            Editable = false;
        }
        field(20;"Shopify Disc App Description";Code[100])
        {
            Editable = false;
        }
        field(30;"Shopify Value";Decimal)
        {
            editable = false;
        }
        field(40;"Shopify Value Type";text[30])
        {
            editable = false;
        }
        field(50;"Shopify Disc Apply Type";Option)
        {
            OptionMembers = Misc,"Buy X Get Y",Discounts,"Auto Order";
        }
        field(60;"Shopify App ID";Integer)
        {
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "Shopify Discount App Type","Shopify Disc App Description")
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        SpOrdLines:record "PC Shopify Order Lines";
    begin
        SpOrdLines.reset;
        SpOrdLines.Setrange("Shopify Application ID",rec."Shopify App ID");
        If SpOrdLines.findset then SpOrdLines.modifyall("Shopify Application ID",0);
    end;
}