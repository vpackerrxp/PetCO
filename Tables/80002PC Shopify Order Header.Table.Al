table 80002 "PC Shopify Order Header"
{
    fields
    {
        field(10;ID; BigInteger)
        {
            AutoIncrement = true;
        }
        field(20;"Shopify Order ID"; BigInteger)
        {
            Editable = False;       
        }
        field(25;"Shopify Order No."; BigInteger)
        {
        }
        field(30;"Transaction Date" ; Date)
        {
            Editable = False;       
        }
        field(40;"Shopify Order Date" ; Date)
        {
            Editable = False;       
        }
        field(50;"Shopify Order Currency"; Code[10])
        {
            Editable = False;       
        }
        field(60;"Credit Card Total"; Decimal)
        {
            Editable = False;       
        }
        field(70;"Gift Card Total";decimal)
        {
            Editable = False;       
        }
        field(80;"Store Credit Total";decimal)
        {
            Editable = False;       
        }
        field(90;"Freight Total";decimal)
        {
            Editable = False;       
        }
        field(100;"Order Type";Option)
        {
            OptionMembers = Invoice,CreditMemo;
            Editable = False;       
        }
        field(110;"BC Reference No.";Code[20])
        {}
        field(120;"Discount Total";decimal)
        {
            Editable = False;       
        }
        field(130;"Fulfilo Shipment Status";option)
        {
            OptionMembers = InComplete,Complete;
            Editable = False;       
        }
        field(140;"Shopify Order Status";Code[20])
        {
            Editable = False;       
        }
        field(150;"Shopify Order Member Status";Code[20])
        {
        }
        field(160;"Order Total";Decimal)
        {
        }
        field(170;"Tax Total";decimal)
        {
            Editable = false;
        }
        field(200;"Order Status";Option)
        {
            OptionMembers = Open,Closed;
        }
        field(210;"Cash Receipt Status";option)
        {
            OptionMembers = UnApplied,Applied;
        }
        field(220;"Invoice Applied Status";option)
        {
            OptionMembers = UnApplied,Applied;
        }
        field(230;"Payment Gate Way";Text[25])
        {
           Editable = false;
        }
        field(240;"Processed Date";Date)
        {
           Editable = false;
        }
        field(250;"Processed Time";Text[15])
        {
           Editable = false;
        }
        field(260;"Proc Time";Time)
        {
           Editable = false;
        }
        field(270;"Transaction Type";text[20])
        {
           Editable = false;
         }
        field(280;"Reference No";text[25])
        {
           Editable = false;
        }
        field(290;"Shopify Financial Status";Text[30])
        {
            Editable = false;
        }
        field(300;"Refunds Checked";Boolean)
        {
            //Editable = false;
        }
        Field(1000;"Shopify Refund Order ID";BigInteger)
        {
            ObsoleteState = Removed;
        }

    }
    keys
    {
        key(PK;ID)
        {
            Clustered = true;
        }
        key(PK2;"Shopify Order ID")
        {
        }
        key(PK3;"Shopify Order No.")
        {
        }
    }
  
    trigger OnDelete()
    var
        Tab:Record "PC Shopify Order Lines";
        App:record "PC Shopfiy Order Applications";
        Excp:record "PC Shopify Order Exceptions";
    begin
        Tab.Reset();
        Tab.setrange("ShopifyID",ID);
        If Tab.findset then Tab.DeleteAll();
        App.Reset;
        App.Setrange("ShopifyID",ID);
        if App.Findset Then App.Deleteall();
        Excp.Reset;
        Excp.Setrange("ShopifyID",ID);
        if Excp.Findset Then Excp.Deleteall();
    end;
    trigger OnInsert()
    begin
        "Transaction Date" := TODAY;
        "Order Status" := "Order Status"::Open;
    end;
   
}