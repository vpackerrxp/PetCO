table 80003 "PC Shopify Order Lines"
{
    fields
    {
        field(10;ID; BigInteger)
        {
            AutoIncrement = true;
        }
        field(20;"ShopifyID";BigInteger)
        {
        }
        field(25;"Order Line ID";BigInteger)
        {
        }
        field(26;"Order Line No";Integer)
        {
        }
        field(30;"Shopify Order ID";BigInteger)
        {
        }
        field(40;"Item No."; Code[20])
        {
        }
        field(50;"Location Code";Code[10])
        {
            TableRelation = Location where("Use As In-Transit"=Const(false));
        }
        field(60;"Unit Of Measure";Code[10])
        {
            TableRelation = "Unit of Measure";
        }
        field(70;"Order Qty";Decimal)
        {
        }
        field(80;"Unit Price";Decimal)
        {
        }
        field(90;"Base Amount";Decimal)
        {
        }
        field(100;"Tax Amount";Decimal)
        {
        }
        field(110;"Discount Amount";Decimal)
        {
        }
        field(120;"FulFilo Shipment Qty";Decimal)
        {
        }
        field(130;"Buy X Get Y";Option)
        {
            OptionMembers = " ","Buy X","Get Y";
        }
        field(140;"Shopify Application Index";integer)
        {
        }
        field(150;"Shopify Application ID";integer)
        {
        }
        field(160;"Bundle Item No.";Code[20])
        {
        }
        field(170;"Bundle Order Qty";Decimal)
        {
        }
        field(180;"Bundle Unit Price";Decimal)
        {
        }
        field(190;"BOM Qty";Decimal)
        {
        }
        field(200;"Auto Delivered";boolean)
        {
           //Editable = false;
        }
        field(210;"Reason Code";Code[20])
        {
           //Editable = false;
        }
        field(220;"Not Supplied";Boolean)
        {
           //Editable = false;
        }
    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        Ordhdr:record "PC Shopify Order Header";
    begin
        Ordhdr.reset;
        Ordhdr.Setrange(ID,rec.ShopifyID);
        If Ordhdr.FindSet() then
            If Ordhdr."Discount Total" > Rec."Discount Amount" then
            begin
                Ordhdr."Discount Total" -= Rec."Discount Amount";
                Ordhdr.modify(false);
            end;
    end;

}