table 80009 "PC Supplier Brand Rebate"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Not Required';
    fields
    {
        field(10;"Supplier No."; Code[20])
        {
            Editable = false;
        }
        field(20;"Brand"; Code[30])
        {
            Editable = false;
        }
        field(21;"Rebate %"; Decimal)
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
        field(70;"Rebate Start Date Period"; Date)
        {
        }
        field(80;"Rebate End Date Period"; Date)
        {
        }
    }
    keys
    {
        key(Key1; "Supplier No.","Brand")
        {
            Clustered = true;
        }
    }
 
}