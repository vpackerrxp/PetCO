tableextension 80005 "PC Vendor Ext" extends Vendor
{
    fields
    {
        field(80000; "Sales E-Mail"; text[80])
        {}
        field(80001; "Operations E-Mail"; text[80])
        {}
        field(80002; "Marketing Rebate %"; Decimal)
        {}
        field(80003; "Supply Chain Rebate %"; Decimal)
        {}
        field(80004; "New DC Pipline Rebate %"; Decimal)
        {
            ObsoleteState = Removed;
        }
        field(80005; "Auto Order Rebate %"; Decimal)
        {
        }
        field(80006; "Palatability Supplier";Boolean)
        {
            ObsoleteState = Removed;
        }
        field(80007; "EDI Status";Option)
        {
            OptionMembers = "Non EDI Vendor","EDI Vendor";
        }
    }
}