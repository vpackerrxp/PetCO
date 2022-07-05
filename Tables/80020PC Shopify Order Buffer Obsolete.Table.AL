table 80020 "PC Shopify Order Buffer"
{
    ObsoleteState = Removed;
    fields
    {
        field(10;"Shopify Order ID"; BigInteger)
        {
            Editable = false;
        }
        field(20;"Shopify Order No."; BigInteger)
        {
            Editable = false;
        }
        field(50;"Shopify Order Date"; Date)
        {
            Editable = false;
        }
        field(60;"Shopify Order Currency"; Code[10])
        {
            Editable = false;
        }
        field(70;"Credit Card Total"; Decimal)
        {
            Editable = false;
        }
        field(80;"Gift Card Total";decimal)
        {
            Editable = false;
        }
        field(90;"Store Credit Total";decimal)
        {
            Editable = false;
        }
        field(100;"Freight Total";decimal)
        {
            Editable = false;
        }
        field(110;"Discount Total";decimal)
        {
            Editable = false;
        }
        field(120;"Order Total";decimal)
        {
        }
        field(130;"Order Line Total";decimal)
        {
            Editable = false;
        }

        field(140;"Tax Total";decimal)
        {
            Editable = false;
        }
        field(150;"Shopify Financial Status";Text[30])
        {
            Editable = false;
        }
        field(160;"Shopify Fullfillment Status";Text[30])
        {
            Editable = false;
        }
        field(170;"Order Type";Option)
        {
            OptionMembers = Invoice,CreditMemo;
        }
        field(180;"BC Reference No.";Code[20])
        {
        }
        field(190;"Is In BC";boolean)
        {
            Editable = false;
        }
        field(200;"Cash Receipt Status";option)
        {
            OptionMembers = UnApplied,Applied;
        }
        field(210;"Invoice Applied Status";option)
        {
            OptionMembers = UnApplied,Applied;
        }
        field(220;"Payment Gate Way";Text[25])
        {
           Editable = false;
        }
        field(230;"Processed Date";Date)
        {
           Editable = false;
        }
        field(235;"Processed Time";Text[15])
        {
           Editable = false;
        }
        field(236;"Proc Time";Time)
        {
           Editable = false;
        }
        field(240;"Transaction Type";text[20])
        {
           Editable = false;
         }
        field(250;"Reference No";text[25])
        {
           Editable = false;
        }
        field(260;"BC Invoice Total";Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Sales Invoice Line"."Line Amount" 
                          where("Document No."=field("BC Reference No.")));
        }
    }
    keys
    {
        key(PK;"Shopify Order ID")
        {
            Clustered = true;
        }
        Key(PK1;"Shopify Order No.")
        {
        }
        Key(PK2;"BC Reference No.")
        {
        }

    } 
    /*
    trigger OnDelete()
    var
        Buffline:record "PC Shopify OrderLine Buffer";
    begin
        Buffline.Reset;
        BuffLine.Setrange("Shopify Order ID",Rec."Shopify Order ID");
        If Buffline.findset then Buffline.DeleteAll();
    end;    
*/

    
}