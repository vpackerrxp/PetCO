pageextension 80011 "PC Genral Ledger Setup Ext" extends "General Ledger Setup"
{
    layout
    {   //dimension Tag
        addafter(Control1900309501)
        {

            Group(PetCulture)
            {
                Group(Rebates)
                {
                    field("Rebate Accural Acc";rec."Rebate Accural Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                      field("Partner Volume Rebate Acc"; rec."Partner Volume Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Marketing Rebate Acc"; rec."Marketing Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("Supply Chain Rebate Acc"; rec."Supply Chain Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("Auto Order Rebate Acc";rec."Auto Order Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("Campaign Rebate Acc";rec."Campaign Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }

                    field("Palatability Rebate Acc";rec."Palatability Rebate Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                }
                Group("Rebate Posting")
                {
                    field("Auto Order Rebate Posting Acc";rec."Auto Order Rebate Posting Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field("Campaign Rebate PostingAcc";rec."Campaign Rebate Posting Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                } 
                Group(Reconcilliation)
                {   
                    field("Reconcillation Bank Acc";rec."Reconcillation Bank Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'Reconcilliation Bank Acc';
                    }
                    field("Reconcillation Clearing Acc";rec."Reconcillation Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'Reconcilliation Clearing Acc';
                    }
                    field("Shopify Pay Clearing Acc";rec."Shopify Pay Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'Shopify Pay Clearing Acc';
                    }
                    field("PayPal Clearing Acc";rec."PayPal Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'PayPal Clearing Acc';
                    }
                    field("AfterPay Clearing Acc";rec."AfterPay Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'AfterPay Clearing Acc';
                    }
                    field("MarketPlace Clearing Acc";rec."MarketPlace Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'MarketPlace Clearing Acc';
                    }
                    field("Zip Clearing Acc";rec."Zip Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'Zip Clearing Acc';
                    }
                    field("Misc Clearing Acc";rec."Misc Clearing Acc")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        caption = 'Misc Clearing Acc';
                    }
                }
            }
        }
    }
}