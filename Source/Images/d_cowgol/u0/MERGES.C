 
int L[500], R[500];

/* Merges two subarrays of arr[].
 First subarray is arr[l..m]
 Second subarray is arr[m+1..r] */
void merge(int arr[], int l, int m, int r)
{
    int i, j, k;
    int n1 = m - l + 1;
    int n2 = r - m;
 
    /* Copy data to temp arrays L[] and R[] */
    for (i = 0; i < n1; i++)
        L[i] = arr[l + i];

    for (j = 0; j < n2; j++)
        R[j] = arr[m + 1 + j];
 
    /* Merge the temp arrays back into arr[l..r] */
    i = 0;
    j = 0;
    k = l;

    while (i < n1 && j < n2) 
    {
        if (L[i] <= R[j]) 
        {
            arr[k] = L[i];
            i++;
        }
        else
        {
            arr[k] = R[j];
            j++;
        }

        k++;
    }
 
    /* Copy the remaining elements of L[], if there are any */
    while (i < n1) 
    {
        arr[k] = L[i];
        i++;
        k++;
    }
 
    /* Copy the remaining elements of R[], if there are any */
    while (j < n2) 
    {
        arr[k] = R[j];
        j++;
        k++;
    }
}
 
/* l is for left index and r is right index of the
 sub-array of arr to be sorted
 first call with l = 0, r = sizeof(arr) - 1 */
void mergeSort(int arr[], int l, int r)
{
    int m;

    if (l < r) 
    {
        m = l + (r - l) / 2;
 
        /* Sort first and second halves */
        mergeSort(arr, l, m);
        mergeSort(arr, m + 1, r);
 
        merge(arr, l, m, r);
    }
}
