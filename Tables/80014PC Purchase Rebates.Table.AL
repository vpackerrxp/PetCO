table 80014 "PC Purchase Rebates"
{
    fields
    {
        field(10;ID; Integer)
        {
            AutoIncrement = true;
        }
        field(20;"Rebate Type"; option)
        {
            OptionMembers = Volume,Marketing,Supply;
        }
        field(30;"Rebate Date"; Date)
        {
        }
        field(40;"Document No."; Code[20])
        {
        }
        field(50;"Supplier No."; code[20])
        {
        }
        field(60;"Item No."; code[20])
        {
        }
        field(70;"Rebate Value"; decimal)
        {
        }
        field(80;"Rebate Paid"; boolean)
        {
        }
        field(90;"Brand"; Code[30])
        {
        }

    }
    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
    
}