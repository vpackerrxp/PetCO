pageextension 80022 "PC Inventory Man Role Center" extends "9008"
{
    actions
    {
        // Adding a new action group 'MyNewActionGroup' in the 'Creation' area
        addbefore("Edit Item Reclassification &Journal")
        {
            group("Analysis")
            {
                group("Sales Analysis")
                {
                    action("Sales Analysis Views")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Sales Analysis Views';
                        Image = AnalysisView;
                        RunObject = Page "Analysis View List Sales";
                        ToolTip = 'Analyze Sales by their dimensions using analysis views that you have set up.';
                    }
                    action("Sales Analysis Report")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Sales Analysis Reports';
                        Image = AnalysisView;
                        RunObject = Page "Analysis Report Sale";
                        ToolTip = 'Analyze Sales by their dimensions using analysis views that you have set up.';
                    }
                    action("Sales Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Sales Analysis by Dimensions';
                        Image = AnalysisView;
                        RunObject = Page "Sales Analysis by Dimensions";
                        ToolTip = 'Analyze Sales by their dimensions using analysis views that you have set up.';
                    }
                }
                group("Purchase Analysis")
                {
                    action("Item Analysis Views")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Analysis Views';
                        Image = AnalysisView;
                        RunObject = Page "Item Analysis View List";
                        ToolTip = 'Analyze Purchases by their dimensions using analysis views that you have set up.';
                    }
                    action("Purchase Analysis Report")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Purchase Analysis Reports';
                        Image = AnalysisView;
                        RunObject = Page "Analysis Report Purchase";
                        ToolTip = 'Analyze Purchases by their dimensions using analysis views that you have set up.';
                    }
                    action("Purchase Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Purchase Analysis by Dimensions';
                        Image = AnalysisView;
                        RunObject = Page "7157";
                        ToolTip = 'Analyze Purchases by their dimensions using analysis views that you have set up.';
                    }
                }
            }
        }
    }
}
