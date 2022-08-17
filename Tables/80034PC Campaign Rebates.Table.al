table 80034 "PC Campaign Rebates"
{
    Caption = 'PC Campaign Rebates';
  
    fields
    {
        field(10;"Rebate Supplier No."; Code[20])
        {
            TableRelation = Vendor."No.";
            Editable = False;
        }
        field(30; Campaign; Code[20])
        {
            Editable = False;
        }
        field(40; "Rebate Type"; Option)
        {
            OptionMembers = Campaign,"Auto Delivery";
            Editable = false;
        }
        field(50; "Campaign Start Date"; Date)
        {
            Editable = False;
        }
        field(60; "Campaign End Date"; Date)
        {
            Editable = False;
        }
        field(70; "Campaign SKUs";Integer)
        {
            FieldClass = FlowField;
            CalcFormula = Count("PC Campaign SKU" Where(Campaign=field(Campaign)));
            trigger OnLookup();
            var
                CSku:record "PC Campaign SKU";
                PG:Page "PC Campaign SKU";
            begin
                CSku.reset;
                CSku.Setrange(Campaign,Rec.Campaign);
                If CSku.Findset then
                begin
                    Pg.SetTableView(CSku);
                    Pg.RunModal();
                end;     
            end;
        }
    }
    keys
    {
        key(PK; "Rebate Supplier No.",Campaign,"Rebate Type")
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        CSku:record "PC Campaign SKU";
        PCPrice:Record "PC Shopfiy Pricing";
    begin
        CSku.Reset;
        CSku.Setrange(Campaign,Rec.Campaign);
        If Csku.Findset then
        repeat
            If Rec."Rebate Type" = Rec."Rebate Type"::Campaign then
            begin
                PCPrice.Reset;
                PCPrice.Setrange("Item No.",CSku.Sku);
                PCPrice.Setrange("Starting Date",Rec."Campaign Start Date");
                PCPrice.Setrange("Ending Date",rec."Campaign End Date");
                If PCPrice.Findset then
                    PCPrice.Delete;
            end;
            CSku.delete;
        until Csku.next = 0;    
    end;
}
