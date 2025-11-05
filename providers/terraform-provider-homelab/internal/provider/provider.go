package provider

import (
    "context"
    "os"

    "github.com/hashicorp/terraform-plugin-framework/datasource"
    "github.com/hashicorp/terraform-plugin-framework/provider"
    "github.com/hashicorp/terraform-plugin-framework/provider/schema"
    "github.com/hashicorp/terraform-plugin-framework/resource"
    "github.com/hashicorp/terraform-plugin-framework/types"

    "terraform-provider-company/internal/provider/client"
)

var _ provider.Provider = &CompanyProvider{}

type CompanyProvider struct {
    version string
}

type CompanyProviderModel struct {
    CMDBEndpoint types.String `tfsdk:"cmdb_endpoint"`
    CMDBToken    types.String `tfsdk:"cmdb_token"`
}

func New(version string) func() provider.Provider {
    return func() provider.Provider {
        return &CompanyProvider{
            version: version,
        }
    }
}

func (p *CompanyProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
    resp.TypeName = "company"
    resp.Version = p.version
}

func (p *CompanyProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "Provider for company VM naming and CMDB integration",
        Attributes: map[string]schema.Attribute{
            "cmdb_endpoint": schema.StringAttribute{
                Description: "CMDB API endpoint URL",
                Optional:    true,
            },
            "cmdb_token": schema.StringAttribute{
                Description: "CMDB API authentication token",
                Optional:    true,
                Sensitive:   true,
            },
        },
    }
}

func (p *CompanyProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
    var config CompanyProviderModel

    resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)
    if resp.Diagnostics.HasError() {
        return
    }

    // Fallback auf Environment Variables
    endpoint := os.Getenv("CMDB_ENDPOINT")
    token := os.Getenv("CMDB_TOKEN")

    if !config.CMDBEndpoint.IsNull() {
        endpoint = config.CMDBEndpoint.ValueString()
    }

    if !config.CMDBToken.IsNull() {
        token = config.CMDBToken.ValueString()
    }

    if endpoint == "" {
        resp.Diagnostics.AddError(
            "Missing CMDB Endpoint",
            "The provider requires a CMDB endpoint. Set it via provider config or CMDB_ENDPOINT environment variable.",
        )
        return
    }

    // CMDB Client initialisieren
    cmdbClient := client.NewCMDBClient(endpoint, token)

    resp.DataSourceData = cmdbClient
    resp.ResourceData = cmdbClient
}

func (p *CompanyProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
    return []func() datasource.DataSource{
        NewNamingDataSource,
    }
}

func (p *CompanyProvider) Resources(ctx context.Context) []func() resource.Resource {
    return []func() resource.Resource{
        NewCMDBEntryResource,
    }
}
