tableextension 80002 "PC Sales Line Ext" extends "Sales Line"
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
        field(80005;"Palatability Reason";Code[30])
        {
            trigger OnLookup()
            var
                pg:page "Dimension Value List";
                DimVal:record "Dimension Value";
                begin
                    DimVal.Reset;
                    Dimval.Setrange("Dimension Code",'REFUNDS');
                    If DimVal.findset then
                    begin
                        Pg.SetTableView(Dimval);
                        Pg.LookupMode := True;
                        If Pg.RunModal() = Action::LookupOK then
                        begin
                            Pg.GetRecord(DimVal);
                            "Palatability Reason":= Dimval.Name.ToUpper();            
                        end;
                    end;
             end;     
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
           Caption = 'Purchase Supplier No.';
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
        field(80011;"Shopify Order Date";Date)
        {
           Editable = false;
        }
        field(80012;"Campaign Rebate";boolean)
        {
           Editable = false;
        }
        field(80013;"Campaign Rebate Supplier";Code[20])
        {
           Editable = false;
        }   
        field(80014;"Auto Delivery Rebate Supplier";Code[20])
        {
           Editable = false;
        }

    }   
}