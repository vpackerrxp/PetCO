table 80036 "PC Campaign SKU New"
{
    Caption = 'Campaign SKU';
   
    fields
    {
        field(10;"Rebate Supplier No."; Code[20])
        {
            Editable = false;
        }
        field(20; Campaign; Code[20])
        {
            Editable = false;
        }
        field(30; SKU; Code[20])
        {
            TableRelation = Item."No.";
            Editable = false;
        }
        field(40; Description;text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No."=field(SKU)));
        }
        field(50; "Campaign Price"; Decimal)
        {
            trigger OnValidate()
            var
                Sprice:Record "PC Shopfiy Pricing";
                CmpReb:record "PC Campaign Rebates";
            begin
                If Rec."Campaign Price" <> xrec."Campaign Price" then
                begin
                    If "Campaign Price" <= 0 then Error('Sell Price Must be > 0');
                    CmpReb.Reset;
                    CmpReb.Setrange("Rebate Supplier No.","Rebate Supplier No.");
                    CmpReb.Setrange(Campaign,rec.Campaign);
                    CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::Campaign);
                    If CmpReb.findset then
                        If Not Sprice.get(rec.Sku,CmpReb."Campaign Start Date") then
                            begin
                                Sprice.init;
                                Sprice."Item No." := Rec.Sku;
                                Sprice."Starting Date" := CmpReb."Campaign Start Date";
                                Sprice.Insert(False);
                            end;    
                            Sprice."Sell Price" := Rec."Campaign Price";
                            Sprice."Platinum Member Disc %" := 0;
                            Sprice."Platinum + Auto Disc %" := 0;
                            Sprice."Gold Member Disc %" := 0;
                            Sprice."Gold + Auto Disc %" := 0;
                            Sprice."Silver Member Disc %" := 0;
                            Sprice."Auto Order Disc %" := 0;
                            Sprice."VIP Disc %" := 0;
                            Sprice."New RRP Price" := Get_RRP();
                            Sprice."Ending Date" := CmpReb."Campaign End Date";
                            Sprice.Modify(False);    
                end;
            end;          
        }
        field(60; "Rebate Amount"; Decimal)
        {
            Caption = 'Rebate %';
        }
    }
    keys
    {
        key(PK;"Rebate Supplier No.",Campaign,SKU)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
       PCPrice:Record "PC Shopfiy Pricing";
       CmpReb:record "PC Campaign Rebates";
    Begin
        CmpReb.Reset;
        CmpReb.Setrange("Rebate Supplier No.",Rec."Rebate Supplier No.");
        CmpReb.Setrange(Campaign,Rec.Campaign);
        CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::Campaign);
        If CmpReb.findset then
        begin
            PCPrice.Reset;
            PCPrice.Setrange("Item No.",Rec.Sku);
            PCPrice.Setrange("Starting Date",CmpReb."Campaign Start Date");
            PCPrice.Setrange("Ending Date",CmpReb."Campaign End Date");
            If PCPrice.Findset then PCPrice.Delete;
        end; 
    end;
    local procedure Get_RRP():Decimal;
    var
       PCPrice:Record "PC Shopfiy Pricing";
       Item:record Item;
    Begin
        PCPrice.Reset;
        PCPrice.Setrange("Item No.",Rec.Sku);
        PCPrice.Setrange("Ending Date",0D);
        If PCPrice.findset then Exit(PCPrice."Sell Price");
        Item.Get(Rec.SKU);
        Exit(Item."Unit Price");    
    End;

    /*trigger OnInsert()
    var
       PCPrice:Record "PC Shopfiy Pricing";
       CmpReb:record "PC Campaign Rebates";
    begin
       CmpReb.Reset;
       CmpReb.Setrange("Rebate Supplier No.",Rec."Rebate Supplier No.")
*/




    //;   




}
