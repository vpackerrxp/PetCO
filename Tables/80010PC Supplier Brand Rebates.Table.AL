table 80010 "PC Supplier Brand Rebates"
{
    fields
    {
        field(10;"Supplier No."; Code[20])
        {
            //Editable = false;
            TableRelation = Vendor."No.";
        }
        field(15;"Rebate Supplier No."; Code[20])
        {
            //Editable = false;
            TableRelation = Vendor."No.";
         }
        field(20;"Brand"; Code[30])
        {
            Editable = false;
        }
        field(30;"Volume Rebate %"; Decimal)
        {
            MaxValue = 100;
        }
        field(40;"Marketing Rebate %"; Decimal)
        {
            MaxValue = 100;
        }
        field(50;"Supply Chain Rebate %"; Decimal)
        {
            MaxValue = 100;
        }
        field(60;"Auto Order Rebate %"; Decimal)
        {
            MaxValue = 100;
        }
        field(65;"Palatability Rebate %"; Decimal)
        {
            MaxValue = 100;
        }
        field(66;"PO Line Disc %"; Decimal)
        {
            MaxValue = 100;
        }
        field(70;"Rebate Start Date Period"; Date)
        {
           editable = false;
        }
        field(80;"Rebate End Date Period"; Date)
        {
            editable = false;
        }
        field(90;"Rebate Status"; Option)
        {
            OptionMembers = Open,Closed;
            editable = false;
        }
    }
    keys
    {
        key(Key1; "Supplier No.","Brand","Rebate Start Date Period")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        If "Rebate Start Date Period" = 0D then Error('Must Define A Rebate Start Date Period');                
        If ("Rebate End Date Period" <> 0D) AND ("Rebate Start Date Period" > "Rebate End Date Period") then
            Error('Rebate Start Date Period Greater Than Rebate End Date Period.. Invalid'); 
     end;
    trigger OnModify()
    begin
        If "Rebate Start Date Period" = 0D then Error('Must Define A Rebate Start Date Period');
        If ("Rebate End Date Period" <> 0D) AND ("Rebate Start Date Period" > "Rebate End Date Period") then
            Error('Rebate Start Date Period Greater Than Rebate End Date Period.. Invalid'); 
    end;
}