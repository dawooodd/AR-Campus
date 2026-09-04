using System;
using System.Collections;
using System.Globalization;
using UnityEngine;
#if UNITY_ADDRESSABLES
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
#endif

/// <summary>
/// Core GPS Player Controller for "Campus Hunto" Unity-as-a-Library (UaaL).
/// Receives real-time GPS coordinate strings from Flutter, converts them into
/// local 3D Cartesian coordinates via Flat-Earth/Equirectangular projection,
/// and moves the character avatar with strict 1:1 metric scale and smooth lerping.
/// </summary>
public class PlayerController : MonoBehaviour
{
    [Header("=== CAMPUS GEOREFERENCE ANCHOR (ORIGIN 0,0,0) ===")]
    [Tooltip("Campus Anchor Latitude (e.g., Main Gate) corresponding to Unity (0, 0, 0)")]
    [SerializeField] private double anchorLatitude = -6.1753924;

    [Tooltip("Campus Anchor Longitude (e.g., Main Gate) corresponding to Unity (0, 0, 0)")]
    [SerializeField] private double anchorLongitude = 106.8271528;

    [Header("=== MOVEMENT & SMOOTHING ===")]
    [Tooltip("Interpolation speed for smooth walking transitions between GPS updates")]
    [SerializeField] private float lerpSpeed = 3.5f;

    [Tooltip("Rotation smoothing speed towards movement vector")]
    [SerializeField] private float rotationSpeed = 8.0f;

    [Tooltip("Fixed character elevation above campus terrain")]
    [SerializeField] private float groundHeightOffset = 0.0f;

    [Header("=== ANIMATION & FEEDBACK ===")]
    [SerializeField] private Animator animator;
    [SerializeField] private ParticleSystem stepDustParticles;

    // Projection Constants (WGS-84 Spheroid Model)
    private const double EarthRadiusMeters = 6378137.0; // Equatorial radius in meters
    private const double Deg2Rad = Math.PI / 180.0;

    // Runtime state
    private Vector3 targetPosition;
    private bool isPositionInitialized = false;
    private double currentLatitude;
    private double currentLongitude;

    // Animator hash constants
    private static readonly int SpeedHash = Animator.StringToHash("Speed");
    private static readonly int IsWalkingHash = Animator.StringToHash("IsWalking");

    private void Awake()
    {
        if (animator == null)
        {
            animator = GetComponentInChildren<Animator>();
        }
    }

    private void Start()
    {
        targetPosition = transform.position;
        Debug.Log($"[PlayerController] Initialized at Anchor ({anchorLatitude:F7}, {anchorLongitude:F7}) -> Unity (0,0,0)");
    }

    private void Update()
    {
        if (!isPositionInitialized) return;

        // Smoothly interpolate towards target GPS position (Vector3.Lerp)
        Vector3 previousPos = transform.position;
        transform.position = Vector3.Lerp(transform.position, targetPosition, Time.deltaTime * lerpSpeed);

        // Calculate planar velocity for rotation and walking animation
        Vector3 moveDelta = transform.position - previousPos;
        moveDelta.y = 0; // Ignore vertical elevation changes for horizontal heading

        float currentSpeed = moveDelta.magnitude / Mathf.Max(Time.deltaTime, 0.001f);

        if (moveDelta.sqrMagnitude > 0.0001f)
        {
            // Face the direction of physical travel
            Quaternion targetRotation = Quaternion.LookRotation(moveDelta.normalized, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * rotationSpeed);

            if (animator != null)
            {
                animator.SetFloat(SpeedHash, currentSpeed);
                animator.SetBool(IsWalkingHash, true);
            }

            if (stepDustParticles != null && !stepDustParticles.isPlaying)
            {
                stepDustParticles.Play();
            }
        }
        else
        {
            if (animator != null)
            {
                animator.SetFloat(SpeedHash, 0f);
                animator.SetBool(IsWalkingHash, false);
            }

            if (stepDustParticles != null && stepDustParticles.isPlaying)
            {
                stepDustParticles.Stop();
            }
        }
    }

    // =========================================================================
    // FLUTTER ⇄ UNITY BRIDGED COMMUNICATION ENTRY POINT
    // =========================================================================

    /// <summary>
    /// Invoked directly by Flutter UaaL via:
    /// _unityWidgetController.postMessage('PlayerController', 'UpdateGPSPosition', "latitude,longitude");
    /// </summary>
    /// <param name="gpsString">Comma-separated GPS string e.g. "-6.17510,106.82680"</param>
    public void UpdateGPSPosition(string gpsString)
    {
        if (string.IsNullOrEmpty(gpsString))
        {
            Debug.LogWarning("[PlayerController] Received empty GPS payload from Flutter.");
            return;
        }

        string[] tokens = gpsString.Split(',');
        if (tokens.Length < 2)
        {
            Debug.LogWarning($"[PlayerController] Malformed GPS string received: '{gpsString}'. Expected 'latitude,longitude'.");
            return;
        }

        // Parse with InvariantCulture to avoid locale comma/dot decimal separator issues
        if (double.TryParse(tokens[0].Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out double lat) &&
            double.TryParse(tokens[1].Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out double lon))
        {
            currentLatitude = lat;
            currentLongitude = lon;

            // Convert GPS LatLng to local meters relative to anchor point
            Vector3 localCoords = GPSToLocalMeters(lat, lon);
            targetPosition = new Vector3(localCoords.x, groundHeightOffset, localCoords.z);

            // Snap immediately on first GPS frame to prevent character flying across map
            if (!isPositionInitialized)
            {
                transform.position = targetPosition;
                isPositionInitialized = true;
                Debug.Log($"[PlayerController] GPS Fix Established: ({lat:F7}, {lon:F7}) -> Unity Local: {targetPosition}");
            }
        }
        else
        {
            Debug.LogError($"[PlayerController] Failed to parse GPS coordinates: '{gpsString}'");
        }
    }

    // =========================================================================
    // MATHEMATICAL PROJECTION: FLAT-EARTH / EQUIRECTANGULAR TO LOCAL METERS
    // =========================================================================

    /// <summary>
    /// Converts real-world Lat/Lng to local metric coordinates relative to the Campus Anchor Point.
    /// Strict 1:1 Scale: 1 Unity Unit = Exactly 1 Real-World Meter.
    /// 
    /// Axis Mapping:
    /// - West to East  -> Local X-Axis (+X = East, -X = West)
    /// - South to North -> Local Z-Axis (+Z = North, -Z = South)
    /// - Elevation      -> Local Y-Axis
    /// </summary>
    public Vector3 GPSToLocalMeters(double latitude, double longitude)
    {
        // Delta radians
        double deltaLatRad = (latitude - anchorLatitude) * Deg2Rad;
        double deltaLonRad = (longitude - anchorLongitude) * Deg2Rad;

        // Mean latitude for meridian convergence correction
        double meanLatRad = anchorLatitude * Deg2Rad;

        // North-South distance in meters (Z-axis in Unity)
        // 1 degree latitude ~= 111,139 meters on WGS-84 ellipsoid
        double deltaZ = deltaLatRad * EarthRadiusMeters;

        // East-West distance in meters (X-axis in Unity) scaled by cosine of latitude
        // 1 degree longitude ~= 111,139 * cos(lat) meters
        double deltaX = deltaLonRad * EarthRadiusMeters * Math.Cos(meanLatRad);

        return new Vector3((float)deltaX, 0f, (float)deltaZ);
    }

    /// <summary>
    /// Inverse projection: Converts Unity local metric position back to real-world LatLng
    /// </summary>
    public Vector2 LocalMetersToGPS(Vector3 localPosition)
    {
        double meanLatRad = anchorLatitude * Deg2Rad;
        double deltaLat = (localPosition.z / EarthRadiusMeters) / Deg2Rad;
        double deltaLon = (localPosition.x / (EarthRadiusMeters * Math.Cos(meanLatRad))) / Deg2Rad;

        return new Vector2((float)(anchorLatitude + deltaLat), (float)(anchorLongitude + deltaLon));
    }

    // =========================================================================
    // ASSET OPTIMIZATION: UNITY ADDRESSABLES ARCHITECTURE NOTE & STREAMER
    // =========================================================================
    /*
     * ARCHITECTURAL NOTE ON 3D ASSET OPTIMIZATION (UAAL / MOBILE):
     * 
     * In a Unity-as-a-Library (UaaL) application, baking extensive high-poly 3D campus
     * building models, textures, and terrain meshes directly into the base scene creates
     * severe mobile issues:
     * 1. Application Package Bloat: The compiled Android AAB / iOS IPA will exceed 150MB+,
     *    discouraging user downloads on mobile data.
     * 2. RAM Exhaustion & Out-Of-Memory (OOM) Crashes: Flutter and Unity share the same OS
     *    process and memory space. Loading all campus buildings at once exhausts GPU VRAM.
     * 
     * RECOMMENDED PATTERN: Unity Addressables / Remote AssetBundles
     * - Campus buildings and POI models should be assigned Addressable addresses:
     *   e.g., "Buildings/Library_Building", "Buildings/Rectorate_Tower".
     * - Buildings are loaded dynamically based on proximity (e.g. within 150m of player)
     *   and unloaded via Addressables.Release() when out of view.
     */

    /// <summary>
    /// Structural Addressables loader boilerplate for dynamic campus POI streaming
    /// </summary>
    public void LoadBuildingAddressable(string addressableKey, Vector3 spawnPosition, Action<GameObject> onLoaded)
    {
#if UNITY_ADDRESSABLES
        Addressables.InstantiateAsync(addressableKey, spawnPosition, Quaternion.identity).Completed += (handle) =>
        {
            if (handle.Status == AsyncOperationStatus.Succeeded)
            {
                Debug.Log($"[PlayerController] Addressable '{addressableKey}' loaded successfully at {spawnPosition}.");
                onLoaded?.Invoke(handle.Result);
            }
            else
            {
                Debug.LogError($"[PlayerController] Failed to load Addressable building: '{addressableKey}'");
            }
        };
#else
        Debug.Log($"[PlayerController] Addressables simulated: Loading placeholder for '{addressableKey}' at {spawnPosition}.");
#endif
    }
}
