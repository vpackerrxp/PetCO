tableextension 80008 "PC General Ledger Setup Ext" extends "General Ledger Setup"
{
    fields
    {
        field(80000;"Partner Volume Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80001;"Marketing Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80002;"Market Rebate %"; Decimal)
        {
            ObsoleteState = Removed;
            MaxValue = 100;
        }
        field(80003;"Supply Chain Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80004;"Supply Chain Rebate %"; Decimal)
        {
            ObsoleteState = Removed;
            MaxValue = 100;
        }
        field(80005;"Auto Order Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80006;"New DC Pipline Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
            ObsoleteState = Removed;
        }
        field(80007;"New DC Pipline Rebate %"; Decimal)
        {
            MaxValue = 100;
            ObsoleteState = Removed;
         }
        field(80008;"Palatability Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80009;"Rebate Accural Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80010;"Reconcillation Bank Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80011;"Reconcillation Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80012;"$0 Sales/Cust Make Good Acc"; Code[20])
        {
            TableRelation = "G/L Account";
            ObsoleteState = Removed;
        }
        field(80013;"Shopify Pay Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80014;"AfterPay Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80015;"PayPal Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80016;"MarketPlace Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80017;"Zip Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80018;"Misc Clearing Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80019;"Campaign Rebate Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80020;"Auto Order Rebate Posting Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(80021;"Campaign Rebate Posting Acc"; Code[20])
        {
            TableRelation = "G/L Account";
        }
    }
}