table 80034 "PC Campaign Rebates"
{
    Caption = 'PC Campaign Rebates';
  
    fields
    {
        field(10;"Rebate Supplier No."; Code[20])
        {
            TableRelation = Vendor."No.";
            //Editable = False;
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
            CalcFormula = Count("PC Campaign SKU New" Where("Rebate Supplier No."=Field("Rebate Supplier No."),Campaign=field(Campaign)));
        }
    }
    keys
    {
        key(PK; "Rebate Supplier No.",Campaign,"Rebate Type")
        {
            Clustered = true;
        }

       key(PK2; Campaign)
        {
        }
    }
    trigger OnDelete()
    var
        CSku:record "PC Campaign SKU New";
    begin
        CSku.Reset;
        Csku.Setrange("Rebate Supplier No.","Rebate Supplier No.");
        CSku.Setrange(Campaign,Rec.Campaign);
        If Csku.Findset then
            CSku.deleteall(true);
    end;
}
