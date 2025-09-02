#include "../Classes/NativeOpenCv.h"
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/types_c.h>
#include <chrono>

#ifdef __ANDROID__
#include <android/log.h>
#endif

#if defined(__GNUC__)
// Attributes to prevent 'unused' function from being removed and to make it visible
    #define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#endif

using namespace cv;
using namespace std;

enum ColorSpace {
    SRC_RGB = 0,
    SRC_BGR,
    SRC_RGBA,
    SRC_YUV,
    SRC_GRAY
};

struct Coordinate
{
    double x;
    double y;
};

struct DetectionResult
{
    Coordinate* topLeft;
    Coordinate* topRight;
    Coordinate* bottomLeft;
    Coordinate* bottomRight;
};

long long int get_now() {
    return chrono::duration_cast<std::chrono::milliseconds>(
            chrono::system_clock::now().time_since_epoch()
    ).count();
}

vector<cv::Point> detect_edges( Mat& image, string outputPath);
vector<vector<cv::Point> > find_squares_ex(Mat& image, string outputPath);

std::vector<cv::Point2f> order_points(const std::vector<cv::Point2f>& pts);

double get_cosine_angle_between_vectors(cv::Point pt1, cv::Point pt2, cv::Point pt0);
float get_height(vector<cv::Point>& square);
float get_width(vector<cv::Point>& square) ;
vector<cv::Point> image_to_vector(Mat& image);

cv::Mat doPerspectiveTransform(cv::Mat image_in, std::vector<cv::Point2f> rectPoints);
std::vector<cv::Point2f> calculateDestinationCorners(const std::vector<cv::Point2f>& pts);
cv::Mat getPerspectiveTransformMatrix(const std::vector<cv::Point2f>& srcPoints, const std::vector<cv::Point2f>& dstPoints);
cv::Mat warpPerspectiveImage(const cv::Mat& srcImage, const cv::Mat& perspectiveTransformMatrix, const cv::Size& outputSize);

void platform_log(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
#ifdef __ANDROID__
    __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
#else
    vprintf(fmt, args);
#endif
    va_end(args);
}

// Avoiding name mangling
extern "C" {

FUNCTION_ATTRIBUTE
const char* version() {
    return CV_VERSION;
}

FUNCTION_ATTRIBUTE
struct Coordinate *create_coordinate(double x, double y)
{
    struct Coordinate *coordinate = (struct Coordinate *)malloc(sizeof(struct Coordinate));
    coordinate->x = x;
    coordinate->y = y;
    return coordinate;
}

FUNCTION_ATTRIBUTE
struct DetectionResult *create_detection_result(Coordinate *topLeft, Coordinate *topRight, Coordinate *bottomLeft, Coordinate *bottomRight)
{
    struct DetectionResult *detectionResult = (struct DetectionResult *)malloc(sizeof(struct DetectionResult));
    detectionResult->topLeft = topLeft;
    detectionResult->topRight = topRight;
    detectionResult->bottomLeft = bottomLeft;
    detectionResult->bottomRight = bottomRight;
    return detectionResult;
}

/// @private
FUNCTION_ATTRIBUTE
struct DetectionResult* detect_document_edges_streaming(
        int32_t width,
        int32_t height,
        int32_t bytesPerPixel,
        u_char *imgBytes,
        char* outputImagePath) {

    long long start = get_now();

    //*
    platform_log("__________ done in w=%d, h=%d, perPixel=%d, path=%s\n", width, height, bytesPerPixel, outputImagePath );

    cv::Mat image = cv::Mat(height, width, CV_8UC(bytesPerPixel), imgBytes);

    //resampleMat(image, SRC_GRAY, 0, 0, 0);


    //cv::Mat image = cv::Mat( height, width, CV_8UC(bytesPerPixel), imgBytes);
    if (image.size().width == 0 || image.size().height == 0) {
        return create_detection_result(
                create_coordinate(0, 0),
                create_coordinate(1, 0),
                create_coordinate(0, 1),
                create_coordinate(1, 1)
        );
    }

    platform_log(" IMAGE w=%d, h=%d\n", image.size().width, image.size().height );

    //*
    std::vector<cv::Point> corners = detect_edges(image, outputImagePath);
    std::vector<cv::Point2f> sortedCorners;
    sortedCorners.push_back(corners[0]);
    sortedCorners.push_back(corners[1]);
    sortedCorners.push_back(corners[2]);
    sortedCorners.push_back(corners[3]);

    platform_log(" Before ORDER POINTS");
    std::vector<cv::Point2f> reorderedPoints = order_points(sortedCorners);
    if (outputImagePath != 0) {
        cv::Mat finalImage = doPerspectiveTransform(image, reorderedPoints);
        //Mat gray0(finalImage.size(), CV_8U), gray;
        //cvtColor(finalImage , gray, COLOR_BGR2GRAY);

        //cv::medianBlur( gray, gray, 3);
        //cv::threshold(gray, gray, 150, 255, cv::THRESH_BINARY);
        //cv::adaptiveThreshold( gray, gray, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 3, 2);
        imwrite(outputImagePath, finalImage);
    }

    platform_log(" AFTER ORDER POINTS");

    int evalInMillis = static_cast<int>(get_now() - start);
    platform_log("Processing done in %dms\n", evalInMillis);

    return create_detection_result(
            create_coordinate(sortedCorners[0].x / image.size().width, sortedCorners[0].y / image.size().height),
            create_coordinate(sortedCorners[1].x / image.size().width, sortedCorners[1].y / image.size().height),
            create_coordinate(sortedCorners[2].x / image.size().width, sortedCorners[2].y / image.size().height),
            create_coordinate(sortedCorners[3].x / image.size().width, sortedCorners[3].y / image.size().height)
    );
    //*/
}

FUNCTION_ATTRIBUTE
struct DetectionResult* detect_document_edges(char* inputImagePath, char* outputImagePath) {
    long long start = get_now();

    cv::Mat image = cv::imread(inputImagePath);

    if (image.size().width == 0 || image.size().height == 0) {
        return create_detection_result(
                create_coordinate(0, 0),
                create_coordinate(1, 0),
                create_coordinate(0, 1),
                create_coordinate(1, 1)
        );
    }

    cv::rotate(image, image, cv::ROTATE_90_CLOCKWISE);

    //vector<cv::Point> points = EdgeDetector::detect_edges_ex_plus(mat);

    int evalInMillis = static_cast<int>(get_now() - start);
    platform_log("Processing done in %dms\n", evalInMillis);

    std::vector<cv::Point> corners = detect_edges(image, outputImagePath);
    std::vector<cv::Point2f> sortedCorners;
    sortedCorners.push_back(corners[0]);
    sortedCorners.push_back(corners[1]);
    sortedCorners.push_back(corners[2]);
    sortedCorners.push_back(corners[3]);

    std::vector<cv::Point2f> reorderedPoints = order_points(sortedCorners);
    if (outputImagePath != 0) {
        cv::Mat finalImage = doPerspectiveTransform(image, reorderedPoints);
        Mat gray0(finalImage.size(), CV_8U), gray;
        cvtColor(finalImage , gray, COLOR_BGR2GRAY);

        cv::medianBlur( gray, gray, 3);
        cv::threshold(gray, gray, 150, 255, cv::THRESH_BINARY);
        //cv::adaptiveThreshold( gray, gray, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 3, 2);
        imwrite(outputImagePath, finalImage);
    }

    return create_detection_result(
            create_coordinate(sortedCorners[0].x / image.size().width, sortedCorners[0].y / image.size().height),
            create_coordinate(sortedCorners[1].x / image.size().width, sortedCorners[1].y / image.size().height),
            create_coordinate(sortedCorners[2].x / image.size().width, sortedCorners[2].y / image.size().height),
            create_coordinate(sortedCorners[3].x / image.size().width, sortedCorners[3].y / image.size().height)
    );
}
}

vector<cv::Point> detect_edges( Mat& image, string outputPath)
{
    //Mat tmpImage = debug_squares(image);
    vector<vector<cv::Point>> squares = find_squares_ex(image, outputPath);
    vector<cv::Point>* biggestSquare = NULL;

    // Sort so that the points are ordered clockwise
    struct sortY {
        bool operator() (cv::Point pt1, cv::Point pt2) { return (pt1.y < pt2.y);}
    } orderRectangleY;
    struct sortX {
        bool operator() (cv::Point pt1, cv::Point pt2) { return (pt1.x < pt2.x);}
    } orderRectangleX;

    for (int i = 0; i < squares.size(); i++) {
        vector<cv::Point>* currentSquare = &squares[i];

        std::sort(currentSquare->begin(),currentSquare->end(), orderRectangleY);
        std::sort(currentSquare->begin(),currentSquare->begin()+2, orderRectangleX);
        std::sort(currentSquare->begin()+2,currentSquare->end(), orderRectangleX);

        float currentSquareWidth = get_width(*currentSquare);
        float currentSquareHeight = get_height(*currentSquare);

        if (currentSquareWidth < image.size().width / 5 || currentSquareHeight < image.size().height / 7) {
            continue;
        }

        if (currentSquareWidth > image.size().width * 0.99 || currentSquareHeight > image.size().height * 0.99) {
            continue;
        }

        if (biggestSquare == NULL) {
            biggestSquare = currentSquare;
            continue;
        }

        float biggestSquareWidth = get_width(*biggestSquare);
        float biggestSquareHeight = get_height(*biggestSquare);

        if (currentSquareWidth * currentSquareHeight >= biggestSquareWidth * biggestSquareHeight) {
            biggestSquare = currentSquare;
        }

    }

    if (biggestSquare == NULL) {
        return image_to_vector(image);
    }

    std::sort(biggestSquare->begin(),biggestSquare->end(), orderRectangleY);
    std::sort(biggestSquare->begin(),biggestSquare->begin()+2, orderRectangleX);
    std::sort(biggestSquare->begin()+2,biggestSquare->end(), orderRectangleX);

    return *biggestSquare;
}

vector<vector<cv::Point> > find_squares_ex(Mat& image, string outputPath)
{
    vector<vector<Point> > squares;

    // Repeated Closing operation to remove text from the document
    cv::Mat kernel = cv::Mat::ones(5, 5, CV_8U);

    // Perform dilation
    cv::Mat dilated;
    cv::dilate(image, dilated, kernel, Point(-1,-1), 3);

    // Perform erosion
    cv::Mat imageMorph;
    cv::erode(dilated, imageMorph, kernel, Point(-1,-1), 3);

    Mat gray0(imageMorph.size(), CV_8U), gray;
    cvtColor(image , gray, COLOR_BGR2GRAY);
    //medianBlur(gray, gray, 3);      // blur will enhance edge detection
    cv::GaussianBlur(gray, gray, cv::Size(11, 11), 0);

    vector<vector<cv::Point> > contours;

    int thresholdLevels[] = {10, 30, 50, 70};
    for(int thresholdLevel : thresholdLevels) {
        Canny(gray, gray0, thresholdLevel, thresholdLevel*3, 3);
        dilate(gray0, gray0, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(8, 8)));

        findContours(gray0, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);

        vector<Point> approx;
        for (const auto & contour : contours) {
            approxPolyDP(Mat(contour), approx, arcLength(Mat(contour), true) * 0.02, true);

            if (approx.size() == 4 && fabs(contourArea(Mat(approx))) > 1000 &&
                isContourConvex(Mat(approx))) {
                double maxCosine = 0;

                for (int j = 2; j < 5; j++) {
                    double cosine = fabs(get_cosine_angle_between_vectors(approx[j % 4], approx[j - 2], approx[j - 1]));
                    maxCosine = MAX(maxCosine, cosine);
                }

                if (maxCosine < 0.3) {
                    squares.push_back(approx);
                }
            }
        }
    }

    return squares;
}

std::vector<cv::Point2f> order_points(const std::vector<cv::Point2f>& pts) {
    std::vector<cv::Point2f> rect(4);
    std::vector<cv::Point2f> pts_copy = pts;

    std::vector<float> sums(pts.size());
    for (int i = 0; i < pts.size(); i++) {
        sums[i] = pts_copy[i].x + pts_copy[i].y;
    }

    // Top-left point will have the smallest sum.
    auto min_sum_it = std::min_element(sums.begin(), sums.end());
    int min_sum_index = std::distance(sums.begin(), min_sum_it);
    rect[0] = pts_copy[min_sum_index];

    // Bottom-right point will have the largest sum.
    auto max_sum_it = std::max_element(sums.begin(), sums.end());
    int max_sum_index = std::distance(sums.begin(), max_sum_it);
    rect[2] = pts_copy[max_sum_index];

    std::vector<float> diffs(pts.size());
    for (int i = 0; i < pts.size(); i++) {
        diffs[i] = pts_copy[i].y - pts_copy[i].x;
    }

    // Top-right point will have the smallest difference.
    auto min_diff_it = std::min_element(diffs.begin(), diffs.end());
    int min_diff_index = std::distance(diffs.begin(), min_diff_it);
    rect[1] = pts_copy[min_diff_index];

    // Bottom-left point will have the largest difference.
    auto max_diff_it = std::max_element(diffs.begin(), diffs.end());
    int max_diff_index = std::distance(diffs.begin(), max_diff_it);
    rect[3] = pts_copy[max_diff_index];

    // Return the ordered coordinates.
    return rect;
}

cv::Mat doPerspectiveTransform(cv::Mat image_in, std::vector<cv::Point2f> rectPoints)
{
    const std::vector<cv::Point2f> destination_corners = calculateDestinationCorners(rectPoints);

    // Create Perspective Transformation Matrix
    cv::Mat M = getPerspectiveTransformMatrix(rectPoints, destination_corners);

    // Execute Perspective Transformation
    cv::Mat transformedImage;
    cv::warpPerspective(image_in, transformedImage, M, cv::Size(destination_corners[2].x, destination_corners[2].y), cv::INTER_LINEAR);

    return transformedImage;
}

std::vector<cv::Point2f> calculateDestinationCorners(const std::vector<cv::Point2f>& pts) {
    cv::Point2f tl = pts[0];
    cv::Point2f tr = pts[1];
    cv::Point2f br = pts[2];
    cv::Point2f bl = pts[3];

    float widthA = std::sqrt(std::pow((br.x - bl.x), 2) + std::pow((br.y - bl.y), 2));
    float widthB = std::sqrt(std::pow((tr.x - tl.x), 2) + std::pow((tr.y - tl.y), 2));
    int maxWidth = static_cast<int>(std::max(widthA, widthB));

    float heightA = std::sqrt(std::pow((tr.x - br.x), 2) + std::pow((tr.y - br.y), 2));
    float heightB = std::sqrt(std::pow((tl.x - bl.x), 2) + std::pow((tl.y - bl.y), 2));
    int maxHeight = static_cast<int>(std::max(heightA, heightB));

    std::vector<cv::Point2f> destinationCorners = {
            cv::Point2f(0, 0),
            cv::Point2f(maxWidth, 0),
            cv::Point2f(maxWidth, maxHeight),
            cv::Point2f(0, maxHeight)
    };

    return destinationCorners;
}

cv::Mat getPerspectiveTransformMatrix(const std::vector<cv::Point2f>& srcPoints, const std::vector<cv::Point2f>& dstPoints) {
    cv::Mat M = cv::getPerspectiveTransform(srcPoints, dstPoints);
    return M;
}

cv::Mat warpPerspectiveImage(const cv::Mat& srcImage, const cv::Mat& perspectiveTransformMatrix, const cv::Size& outputSize) {
    cv::Mat warpedImage;
    cv::warpPerspective(srcImage, warpedImage, perspectiveTransformMatrix, outputSize, cv::INTER_LINEAR);
    return warpedImage;
}

// helper function:
// finds a cosine of angle between vectors
// from pt0->pt1 and from pt0->pt2
double get_cosine_angle_between_vectors(cv::Point pt1, cv::Point pt2, cv::Point pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

float get_height(vector<cv::Point>& square) {
    float upperLeftToLowerRight = square[3].y - square[0].y;
    float upperRightToLowerLeft = square[1].y - square[2].y;

    return max(upperLeftToLowerRight, upperRightToLowerLeft);
}

float get_width(vector<cv::Point>& square) {
    float upperLeftToLowerRight = square[3].x - square[0].x;
    float upperRightToLowerLeft = square[1].x - square[2].x;

    return max(upperLeftToLowerRight, upperRightToLowerLeft);
}

vector<cv::Point> image_to_vector(Mat& image)
{
    int imageWidth = image.size().width;
    int imageHeight = image.size().height;

    return {
            cv::Point(0, 0),
            cv::Point(imageWidth, 0),
            cv::Point(0, imageHeight),
            cv::Point(imageWidth, imageHeight)
    };
}