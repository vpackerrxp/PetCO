table 80035 "PC Campaign SKU"
{
    Caption = 'Campaign SKU';
   
    fields
    {
        field(10; Campaign; Code[20])
        {
        }
        field(20; SKU; Code[20])
        {
            TableRelation = Item."No.";
        }
        field(30; "Campaign Price"; Decimal)
        {
            trigger OnValidate()
            var
                Sprice:Record "PC Shopfiy Pricing";
                CmpReb:record "PC Campaign Rebates";
            begin
                If Rec."Campaign Price" <> xrec."Campaign Price" then
                begin
                    CmpReb.Reset;
                    CmpReb.Setrange(Campaign,rec.Campaign);
                    If CmpReb.findset then
                        If CmpReb."Rebate Type" = CmpReb."Rebate Type"::Campaign Then
                        begin
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
                            Sprice."New RRP Price" := Rec."Campaign Price";
                            Sprice."Ending Date" := CmpReb."Campaign End Date";
                            Sprice.Modify(False);    
                        end;
                end;
            end;          
        }
        field(40; "Rebate Amount"; Decimal)
        {
        }
    }
    keys
    {
        key(PK; Campaign,SKU)
        {
            Clustered = true;
        }
    }
}
