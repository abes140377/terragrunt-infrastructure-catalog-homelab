package provider

import (
    "context"
    "fmt"
    "strings"

    "github.com/hashicorp/terraform-plugin-framework/datasource"
    "github.com/hashicorp/terraform-plugin-framework/datasource/schema"
    "github.com/hashicorp/terraform-plugin-framework/types"
)

var _ datasource.DataSource = &NamingDataSource{}

func NewNamingDataSource() datasource.DataSource {
    return &NamingDataSource{}
}

type NamingDataSource struct{}

type NamingDataSourceModel struct {
    Environment types.String `tfsdk:"environment"`
    Application types.String `tfsdk:"application"`
    Instance    types.String `tfsdk:"instance"`
    Region      types.String `tfsdk:"region"`
    VMName      types.String `tfsdk:"vm_name"`
}

func (d *NamingDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
    resp.TypeName = req.ProviderTypeName + "_naming"
}

func (d *NamingDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "Generates VM names according to company naming convention",
        Attributes: map[string]schema.Attribute{
            "environment": schema.StringAttribute{
                Description: "Environment (dev, test, prod)",
                Required:    true,
            },
            "application": schema.StringAttribute{
                Description: "Application name",
                Required:    true,
            },
            "instance": schema.StringAttribute{
                Description: "Instance number",
                Required:    true,
            },
            "region": schema.StringAttribute{
                Description: "Region code",
                Optional:    true,
            },
            "vm_name": schema.StringAttribute{
                Description: "Generated VM name",
                Computed:    true,
            },
        },
    }
}

func (d *NamingDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
    var data NamingDataSourceModel

    resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
    if resp.Diagnostics.HasError() {
        return
    }

    // Hier Ihre Naming-Logik implementieren
    vmName := d.generateVMName(
        data.Environment.ValueString(),
        data.Application.ValueString(),
        data.Instance.ValueString(),
        data.Region.ValueString(),
    )

    data.VMName = types.StringValue(vmName)

    resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (d *NamingDataSource) generateVMName(env, app, instance, region string) string {
    // Beispiel Naming Convention: <env>-<region>-<app>-<instance>
    // z.B.: prod-eu-webapp-001

    parts := []string{}

    if env != "" {
        parts = append(parts, strings.ToLower(env))
    }

    if region != "" {
        parts = append(parts, strings.ToLower(region))
    }

    if app != "" {
        parts = append(parts, strings.ToLower(app))
    }

    if instance != "" {
        parts = append(parts, fmt.Sprintf("%03s", instance))
    }

    return strings.Join(parts, "-")
}
