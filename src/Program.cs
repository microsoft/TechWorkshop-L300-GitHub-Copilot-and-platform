using ZavaStorefront.Services;
using ZavaStorefront.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

// Add session support
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

// Register application services
builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<ProductService>();
builder.Services.AddScoped<CartService>();
builder.Services.Configure<FoundryOptions>(builder.Configuration.GetSection("Foundry"));
builder.Services.PostConfigure<FoundryOptions>(options =>
{
    options.Endpoint = builder.Configuration["AZURE_FOUNDRY_ENDPOINT"] ?? options.Endpoint;
    options.ApiKey = builder.Configuration["AZURE_FOUNDRY_API_KEY"] ?? options.ApiKey;
    options.DeploymentName = builder.Configuration["AZURE_FOUNDRY_DEPLOYMENT"] ?? options.DeploymentName;
    options.ApiVersion = builder.Configuration["AZURE_FOUNDRY_API_VERSION"] ?? options.ApiVersion;
});
builder.Services.AddHttpClient<FoundryChatService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseSession();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
